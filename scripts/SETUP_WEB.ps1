$ErrorActionPreference = 'Stop'
Get-Command node.exe,npm.cmd -ErrorAction Stop | Out-Null
if ([int]((node.exe --version).TrimStart('v').Split('.')[0]) -lt 24) {
    throw 'Install Node.js 24 or newer before setting up Hanoi Guide Web.'
}
Push-Location (Join-Path $PSScriptRoot '../hanoi-guide-web')
try {
    npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw 'Web dependency installation failed.' }
    Write-Host 'Start the API, then run scripts/START_WEB.ps1.'
} finally { Pop-Location }
