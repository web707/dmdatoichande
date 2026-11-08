param([string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin', [int]$PgPort = 55432)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$localRoot = Join-Path $projectRoot '.local'
$dataPath = Join-Path $localRoot 'pgdata'
if (-not $projectRoot.StartsWith('D:\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Run this project from drive D.' }
New-Item -ItemType Directory -Force -Path $localRoot | Out-Null
$envPath = Join-Path $projectRoot 'backend\.env'
if (-not (Test-Path -LiteralPath $envPath)) {
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create(); $b24 = New-Object byte[] 24; $rng.GetBytes($b24); $dbPassword = [System.BitConverter]::ToString($b24).Replace("-", "").ToLowerInvariant()
    $b12 = New-Object byte[] 12; $rng.GetBytes($b12); $adminPassword = [System.BitConverter]::ToString($b12).Replace("-", "").ToLowerInvariant()
    @"
DATABASE_URL=postgresql://hanoi_owner:${dbPassword}@127.0.0.1:${PgPort}/hanoi_guide
PORT=8090
HOST=127.0.0.1
WEB_ORIGINS=http://localhost:8080,http://127.0.0.1:8080,http://localhost:8090,http://127.0.0.1:8090
ADMIN_EMAIL=admin@hanoi.local
ADMIN_PASSWORD=$adminPassword
"@ | Set-Content -LiteralPath $envPath -Encoding utf8
    @"
Hanoi Guide local demo
Admin email: admin@hanoi.local
Admin password: $adminPassword
Credentials are for this local prototype only. Do not commit this file.
"@ | Set-Content -LiteralPath (Join-Path $localRoot 'admin-credentials.txt') -Encoding utf8
}
if (-not (Test-Path -LiteralPath (Join-Path $dataPath 'PG_VERSION'))) {
    $dbLine = Get-Content -LiteralPath $envPath | Where-Object { $_ -like 'DATABASE_URL=*' }
    $dbUri = [Uri]($dbLine.Substring('DATABASE_URL='.Length))
    $dbPassword = $dbUri.UserInfo.Split(':')[1]
    $pwPath = Join-Path $localRoot 'initdb-password.tmp'
    try {
        [IO.File]::WriteAllText($pwPath, $dbPassword, [Text.UTF8Encoding]::new($false))
        & (Join-Path $PgBin 'initdb.exe') -D $dataPath -U hanoi_owner --auth=scram-sha-256 --encoding=UTF8 --locale=C --pwfile=$pwPath
        if ($LASTEXITCODE -ne 0) { throw 'initdb failed.' }
    } finally { Remove-Item -LiteralPath $pwPath -ErrorAction SilentlyContinue }
    Add-Content -LiteralPath (Join-Path $dataPath 'postgresql.conf') -Value "`nport = $PgPort`nlisten_addresses = '127.0.0.1'"
}
& (Join-Path $PgBin 'pg_ctl.exe') -D $dataPath status *> $null
if ($LASTEXITCODE -ne 0) {
    & (Join-Path $PgBin 'pg_ctl.exe') -D $dataPath -l (Join-Path $localRoot 'postgres.log') -w start
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL did not start. Check .local/postgres.log.' }
}
$dbLine = Get-Content -LiteralPath $envPath | Where-Object { $_ -like 'DATABASE_URL=*' }
$dbUri = [Uri]($dbLine.Substring('DATABASE_URL='.Length))
$previousPassword = $env:PGPASSWORD
try {
    $env:PGPASSWORD = $dbUri.UserInfo.Split(':')[1]
    $exists = & (Join-Path $PgBin 'psql.exe') -h 127.0.0.1 -p $PgPort -U hanoi_owner -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='hanoi_guide'"
    if ($LASTEXITCODE -ne 0) { throw 'Cannot connect to local database.' }
    if ($exists -ne '1') {
        & (Join-Path $PgBin 'createdb.exe') -h 127.0.0.1 -p $PgPort -U hanoi_owner hanoi_guide
        if ($LASTEXITCODE -ne 0) { throw 'Database creation failed.' }
    }
} finally { $env:PGPASSWORD = $previousPassword }
Write-Host "PostgreSQL ready on 127.0.0.1:$PgPort. Data: $dataPath"
Write-Host 'Local admin credentials: .local/admin-credentials.txt'

