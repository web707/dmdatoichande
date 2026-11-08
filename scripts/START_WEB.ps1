param(
    [uri]$ApiUrl = 'http://127.0.0.1:8090',
    [switch]$Production
)
$ErrorActionPreference = 'Stop'
Get-Command npm.cmd -ErrorAction Stop | Out-Null
if (-not $ApiUrl.IsAbsoluteUri -or $ApiUrl.Scheme -notin @('http', 'https') -or
    $ApiUrl.UserInfo -or $ApiUrl.AbsolutePath -ne '/' -or $ApiUrl.Query -or $ApiUrl.Fragment) {
    throw 'ApiUrl must be an HTTP(S) origin without credentials.'
}
$previousApiUrl = $env:HANOI_GUIDE_API_URL
Push-Location (Join-Path $PSScriptRoot '../hanoi-guide-web')
try {
    if (-not (Test-Path -LiteralPath 'node_modules/next')) { throw 'Run scripts/SETUP_WEB.ps1 first.' }
    $env:HANOI_GUIDE_API_URL = $ApiUrl.AbsoluteUri.TrimEnd('/')
    if ($Production) {
        if (-not (Test-Path -LiteralPath '.next/BUILD_ID')) { throw 'Run npm run build in hanoi-guide-web first.' }
        npm.cmd start
    } else {
        npm.cmd run dev
    }
    if ($LASTEXITCODE -ne 0) { throw 'The Web server exited with an error.' }
} finally {
    $env:HANOI_GUIDE_API_URL = $previousApiUrl
    Pop-Location
}
