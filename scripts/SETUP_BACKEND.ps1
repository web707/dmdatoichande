$ErrorActionPreference = 'Stop'
Get-Command node.exe,npm.cmd -ErrorAction Stop | Out-Null
if ([int]((node.exe --version).TrimStart('v').Split('.')[0]) -lt 24) {
    throw 'Install Node.js 24 or newer before setting up Hanoi Guide Backend.'
}
Push-Location (Join-Path $PSScriptRoot '../backend')
try {
    npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw 'Backend dependency installation failed.' }
    if (-not $env:DATABASE_URL -and -not (Test-Path -LiteralPath '.env')) {
        Write-Host 'Set DATABASE_URL or configure backend/.env from backend/.env.example.'
    }
    Write-Host 'Backend dependencies are ready. Start an already provisioned PostgreSQL database, then run scripts/START_BACKEND.ps1.'
} finally { Pop-Location }
