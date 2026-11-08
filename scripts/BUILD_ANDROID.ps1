param(
    [switch]$Release,
    [string]$ApiUrl,
    [switch]$NoDaemon
)
$ErrorActionPreference = 'Stop'
if ($Release -and -not $ApiUrl) { throw 'Specify -ApiUrl with an HTTPS API origin for a release build.' }
if ($ApiUrl) {
    $parsed = $ApiUrl -as [uri]
    if (-not $parsed -or -not $parsed.IsAbsoluteUri -or $parsed.Scheme -notin @('http', 'https') -or
        $parsed.UserInfo -or $parsed.AbsolutePath -ne '/' -or $parsed.Query -or $parsed.Fragment) {
        throw 'ApiUrl must be an HTTP(S) origin without credentials.'
    }
    if ($Release -and $parsed.Scheme -ne 'https') { throw 'Release builds require HTTPS.' }
}
$variant = if ($Release) { 'Release' } else { 'Debug' }
$arguments = @(":androidApp:assemble$variant")
if ($ApiUrl) { $arguments += "-PHANOI_$($variant.ToUpperInvariant())_API_BASE_URL=$ApiUrl" }
if ($NoDaemon) { $arguments += '--no-daemon' }
Push-Location (Join-Path $PSScriptRoot '../hanoi-guide-mobile')
try {
    .\gradlew.bat @arguments
    if ($LASTEXITCODE -ne 0) { throw "Android $variant build failed." }
} finally { Pop-Location }
