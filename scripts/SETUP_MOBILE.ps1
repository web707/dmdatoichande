$ErrorActionPreference = 'Stop'
if ($env:JAVA_HOME) {
    $java = Join-Path $env:JAVA_HOME 'bin/java.exe'
    if (-not (Test-Path -LiteralPath $java)) { throw 'JAVA_HOME must point to a valid JDK.' }
} else {
    $java = (Get-Command java.exe -ErrorAction Stop).Source
}
$javaVersion = & $java -version 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $javaVersion -notmatch 'version "(\d+)' -or [int]$Matches[1] -lt 17) {
    throw 'Install a compatible JDK (17 or newer) and set JAVA_HOME.'
}
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
if (-not $sdk -or -not (Test-Path -LiteralPath (Join-Path $sdk 'platforms/android-36')) -or
    -not (Test-Path -LiteralPath (Join-Path $sdk 'build-tools/36.0.0'))) {
    throw 'Set ANDROID_HOME to an SDK with Android Platform 36 and Build Tools 36.0.0 installed.'
}
Push-Location (Join-Path $PSScriptRoot '../hanoi-guide-mobile')
try {
    .\gradlew.bat --version
    if ($LASTEXITCODE -ne 0) { throw 'Gradle wrapper could not start.' }
    Write-Host 'Run scripts/BUILD_ANDROID.ps1 to compile the native Android application.'
} finally { Pop-Location }
