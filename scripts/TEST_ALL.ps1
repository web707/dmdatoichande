param(
    [string]$TestDatabaseUrl = $env:HANOI_TEST_DATABASE_URL,
    [switch]$SkipFlutter
)
$ErrorActionPreference = 'Stop'
Get-Command node.exe,npm.cmd -ErrorAction Stop | Out-Null
$database = $TestDatabaseUrl -as [uri]
if (-not $database -or -not $database.IsAbsoluteUri -or
    $database.Scheme -notin @('postgres', 'postgresql') -or
    -not $database.IsLoopback -or $database.Query -or $database.Fragment -or
    $database.AbsolutePath -notmatch '^/hanoi_modernization_verify_[a-z0-9_]+$') {
    throw 'Set HANOI_TEST_DATABASE_URL to a local disposable restored database named hanoi_modernization_verify_*, without query options. The API tests perform writes.'
}

function Invoke-Check([string]$Directory, [string]$Executable, [string[]]$Arguments) {
    Push-Location (Join-Path $PSScriptRoot $Directory)
    try {
        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) { throw "$Executable $($Arguments -join ' ') failed in $Directory." }
    } finally { Pop-Location }
}

$previousDatabaseUrl = $env:DATABASE_URL
try {
    $env:DATABASE_URL = $TestDatabaseUrl
    Invoke-Check '../backend' 'npm.cmd' @('run', 'build')
    Invoke-Check '../backend' 'npm.cmd' @('test')
} finally { $env:DATABASE_URL = $previousDatabaseUrl }

Invoke-Check '../hanoi-guide-contracts' 'node.exe' @('generate.mjs', '--check')
Invoke-Check '../hanoi-guide-web' 'npm.cmd' @('run', 'contract:check')
Invoke-Check '../hanoi-guide-web' 'npm.cmd' @('run', 'lint')
Invoke-Check '../hanoi-guide-web' 'npm.cmd' @('run', 'typecheck')
Invoke-Check '../hanoi-guide-web' 'npm.cmd' @('run', 'build')
Invoke-Check '../hanoi-guide-web' 'npm.cmd' @('run', 'test:e2e')
Invoke-Check '..' 'git.exe' @(
    'diff', '--no-index', '--ignore-cr-at-eol', '--',
    'hanoi-guide-contracts/generated-kotlin/Destinations.kt',
    'hanoi-guide-mobile/shared/src/commonMain/kotlin/com/hanoiguide/contracts/Destinations.kt'
)
Invoke-Check '../hanoi-guide-mobile' '.\gradlew.bat' @(':shared:testAndroidHostTest', ':androidApp:assembleDebug')
if (-not $SkipFlutter) {
    Invoke-Check '..' 'flutter.bat' @('analyze', '--no-pub')
    Invoke-Check '..' 'flutter.bat' @('test', '--no-pub')
}
