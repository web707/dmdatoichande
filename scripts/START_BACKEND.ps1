$ErrorActionPreference = 'Stop'
Get-Command node.exe,npm.cmd -ErrorAction Stop | Out-Null
Push-Location (Join-Path $PSScriptRoot '../backend')
try {
    if (-not $env:DATABASE_URL -and -not (Test-Path -LiteralPath '.env')) { throw 'Set DATABASE_URL or configure backend/.env first.' }
    if (-not (Test-Path -LiteralPath 'node_modules/tsx')) { throw 'Run scripts/SETUP_BACKEND.ps1 first.' }
    npm.cmd start
    if ($LASTEXITCODE -ne 0) { throw 'The Backend server exited with an error.' }
} finally { Pop-Location }
