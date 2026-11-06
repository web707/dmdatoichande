$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'backend\.env'))) { throw 'Run scripts/setup-local.ps1 first.' }
$listener = Get-NetTCPConnection -LocalPort 8090 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    try {
        $health = Invoke-RestMethod http://127.0.0.1:8090/api/health -TimeoutSec 3
        if ($health.database -eq 'postgresql') { Write-Host 'API is already running at http://localhost:8090'; return }
    } catch {}
    throw 'Port 8090 is in use by another service. Stop it or configure a different port.'
}
$process = Start-Process -FilePath (Get-Command node).Source -ArgumentList '--import','tsx',(Join-Path $projectRoot 'backend\src\server.ts') -WorkingDirectory (Join-Path $projectRoot 'backend') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $projectRoot '.local\api.log') -RedirectStandardError (Join-Path $projectRoot '.local\api-error.log') -PassThru
$process.Id | Set-Content -LiteralPath (Join-Path $projectRoot '.local\api.pid')
Write-Host 'API started. Open http://localhost:8090 after building Flutter Web.'
