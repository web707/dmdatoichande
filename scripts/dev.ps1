$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$apiUrl = 'http://127.0.0.1:8090'
$webUrl = 'http://127.0.0.1:1503/destinations'
$serial = 'emulator-5554'
$avd = if ($env:HANOI_ANDROID_AVD) { $env:HANOI_ANDROID_AVD } else { 'Hanoi_VR360_API_34' }
$logDir = Join-Path $root '.local/dev'

function Test-Port([int]$port) {
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $client.Connect('127.0.0.1', $port)
        return $true
    } catch [Net.Sockets.SocketException] {
        return $false
    } finally { $client.Dispose() }
}

function Wait-Until([scriptblock]$ready, [int]$seconds, [string]$failure) {
    $deadline = [Diagnostics.Stopwatch]::StartNew()
    do {
        if (& $ready) { return }
        Start-Sleep -Seconds 1
    } while ($deadline.Elapsed.TotalSeconds -lt $seconds)
    throw $failure
}

function Start-ServiceProcess([string]$name, [string[]]$arguments, [string]$directory) {
    Start-Process -FilePath $node -ArgumentList $arguments -WorkingDirectory $directory -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logDir "$name.log") `
        -RedirectStandardError (Join-Path $logDir "$name-error.log")
}

function Stop-OwnedProcess($process) {
    if ($process -and -not $process.HasExited) {
        & taskkill.exe /PID $process.Id /T /F *> $null
    }
}

function Test-Api {
    try {
        $catalog = Invoke-RestMethod "$apiUrl/api/v1/destinations?limit=1" -NoProxy -TimeoutSec 3
        return $null -ne $catalog.PSObject.Properties['items']
    } catch { return $false }
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
try {
    $lock = [IO.File]::Open((Join-Path $logDir 'launcher.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
} catch [IO.IOException] {
    throw 'dev.sh is already running in this workspace. Press Ctrl+C in its terminal before restarting.'
}

$backend = $web = $emulator = $null
try {
    $node = (Get-Command node.exe -ErrorAction Stop).Source
    Get-Command npm.cmd -ErrorAction Stop | Out-Null
    $sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { (Join-Path $env:LOCALAPPDATA "Android\Sdk") }
    if (-not $sdk) { throw 'Set ANDROID_HOME to the Android SDK directory.' }
    $adb = Join-Path $sdk 'platform-tools/adb.exe'
    $emulatorExe = Join-Path $sdk 'emulator/emulator.exe'
    if (-not (Test-Path -LiteralPath $adb) -or -not (Test-Path -LiteralPath $emulatorExe)) {
        throw 'Install Android SDK Platform-Tools and Android Emulator.'
    }
    if ((& $emulatorExe -list-avds) -cnotcontains $avd) {
        $installedAvds = @(& $emulatorExe -list-avds)
        if ($installedAvds.Count -gt 0) {
            $avd = $installedAvds[0]
            Write-Host "AVD default not found. Using installed AVD: '$avd'"
        } else {
            throw "Android AVD '$avd' was not found. Set HANOI_ANDROID_AVD to an installed AVD name."
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'backend/.env'))) {
        throw 'Provision the local PostgreSQL catalog first using the repository README.'
    }
    if (Test-Port 1503) { throw 'Web port 1503 is already in use.' }

    $reuseBackend = Test-Port 8090
    if ($reuseBackend -and -not (Test-Api)) { throw 'Port 8090 is in use by an API without a working Hanoi Guide catalog.' }
    if (-not $reuseBackend -and -not (Test-Port 55432)) { & (Join-Path $PSScriptRoot 'setup-local.ps1') }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'backend/node_modules/tsx'))) {
        & (Join-Path $PSScriptRoot 'SETUP_BACKEND.ps1')
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'hanoi-guide-web/node_modules/next'))) {
        & (Join-Path $PSScriptRoot 'SETUP_WEB.ps1')
    }

    $matchingDevices = @(foreach ($line in (& $adb devices)) {
        if ($line -match '^(emulator-(\d+))\s') {
            $device = $Matches[1]
            $port = [int]$Matches[2]
            if ((& $adb -s $device emu avd name 2>$null) -ccontains $avd) {
                [pscustomobject]@{ Serial = $device; Port = $port }
            }
        }
    })
    if ((Test-Port 5554) -and $serial -notin $matchingDevices.Serial) {
        throw 'Emulator port 5554 is occupied by a different or unidentifiable device.'
    }
    foreach ($device in $matchingDevices) {
        Write-Host "Stopping '$avd' ($($device.Serial)) before the cold boot..."
        & $adb -s $device.Serial emu kill
        if ($LASTEXITCODE) { throw "Could not stop $($device.Serial)." }
        Wait-Until { -not (Test-Port $device.Port) } 45 "Emulator $($device.Serial) did not stop."
    }
    if ((Test-Port 5554) -or (Test-Port 5555)) { throw 'Android Emulator needs ports 5554 and 5555.' }

    Write-Host 'Building the Android debug APK...'
    & (Join-Path $PSScriptRoot 'BUILD_ANDROID.ps1') -ApiUrl 'http://10.0.2.2:8090' -NoDaemon
    if ($reuseBackend) {
        Write-Host "Using the running Hanoi Guide API at $apiUrl."
    } else {
        $env:PORT = '8090'
        $env:HOST = '127.0.0.1'
        $backend = Start-ServiceProcess 'backend' @('--import', 'tsx', 'src/server.ts') (Join-Path $root 'backend')
        Wait-Until { -not $backend.HasExited -and (Test-Api) } 30 'Backend failed to serve the catalog. Check .local/dev/backend-error.log.'
    }
    $env:HANOI_GUIDE_API_URL = $apiUrl
    $web = Start-ServiceProcess 'web' @('node_modules/next/dist/bin/next', 'dev', '--hostname', '127.0.0.1', '--port', '1503') (Join-Path $root 'hanoi-guide-web')
    Wait-Until {
        if ($web.HasExited) { throw 'Web exited. Check .local/dev/web-error.log.' }
        try { (Invoke-WebRequest $webUrl -NoProxy -TimeoutSec 10).StatusCode -eq 200 } catch { $false }
    } 90 'Web did not respond. Check .local/dev/web-error.log.'
    Write-Host "Web ready: $webUrl"

    Write-Host "Cold-booting '$avd' with snapshot loading and saving disabled..."
    $emulator = Start-Process -FilePath $emulatorExe -ArgumentList @('-avd', ('"' + $avd + '"'), '-port', '5554', '-no-snapshot') `
        -WindowStyle Normal -PassThru -RedirectStandardOutput (Join-Path $logDir 'emulator.log') `
        -RedirectStandardError (Join-Path $logDir 'emulator-error.log')
    Wait-Until {
        if ($emulator.HasExited) { throw 'Emulator exited. Check .local/dev/emulator-error.log.' }
        ((& $adb -s $serial shell getprop sys.boot_completed 2>$null) -join '').Trim() -eq '1'
    } 240 'Android did not finish booting. Check .local/dev/emulator-error.log.'
    $apk = Join-Path $root 'hanoi-guide-mobile/androidApp/build/outputs/apk/debug/androidApp-debug.apk'
    & $adb -s $serial install -r $apk
    if ($LASTEXITCODE) { throw 'Android APK installation failed.' }
    & $adb -s $serial shell wm dismiss-keyguard
    $launch = & $adb -s $serial shell am start -W -n 'vn.hanoiguide.mobile.debug/vn.hanoiguide.mobile.MainActivity'
    $launch | Write-Host
    if ($LASTEXITCODE -or $launch -notcontains 'Status: ok') { throw 'Android app failed to start.' }

    Write-Host "Android ready: $serial. Press Ctrl+C to stop this dev session."
    while (-not $web.HasExited -and -not $emulator.HasExited -and (-not $backend -or -not $backend.HasExited)) {
        Start-Sleep -Seconds 2
    }
    throw 'A dev process exited. Check the logs in .local/dev/.'
} finally {
    if ($emulator -and -not $emulator.HasExited) {
        & $adb -s $serial emu kill *> $null
        if (-not $emulator.WaitForExit(10000)) { Stop-OwnedProcess $emulator }
    }
    Stop-OwnedProcess $web
    Stop-OwnedProcess $backend
    $lock.Dispose()
}
