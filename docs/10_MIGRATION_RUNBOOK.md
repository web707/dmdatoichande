# Migration runbook

## Parallel development

1. Identify the database and record the source Git revision. Read the existing schema and migration ledger.
2. Start the existing loopback PostgreSQL cluster if it is stopped. See [legacy setup](../README.md) for first-time local provisioning. Keep startup separate from migration and seed commands.
3. Use the Windows setup and start scripts in [scripts](../scripts). Keep Flutter on 8080, Express on 8090 and the new Web project on 8081. Android emulator debug uses `10.0.2.2:8090`.
4. Run API write tests against a disposable restore. Use the original database for read-only smoke checks.
5. Compare old and versioned endpoints and retain the old clients until feature gates pass.

## Backup and disposable restore

Supply `PGHOST`, `PGPORT`, `PGUSER` and the password through an existing secure PostgreSQL client configuration. Verify that the source is the intended database. Use the PostgreSQL installation's `pg_dump.exe`, `createdb.exe`, `pg_restore.exe` and `psql.exe` on Windows. Use a fresh destination name and a protected dump directory.

```powershell
$restoreDb = 'hanoi_modernization_verify_' + (Get-Date -Format 'yyyyMMddHHmmss')
$dumpPath = Join-Path (Resolve-Path '.local') "$restoreDb.dump"
pg_dump -Fc --no-owner --no-privileges -f $dumpPath -d hanoi_guide
if ($LASTEXITCODE -ne 0) { throw 'Backup failed' }
createdb --maintenance-db=postgres $restoreDb
if ($LASTEXITCODE -ne 0) { throw 'Disposable database creation failed' }
pg_restore --exit-on-error --single-transaction --no-owner --no-privileges -d $restoreDb $dumpPath
if ($LASTEXITCODE -ne 0) { throw 'Restore failed' }
```

Compare schema, migration ledger, row counts and ordered row fingerprints before testing. This was done on the local PostgreSQL 18.1 database with all eight tables matching. The local dump and disposable database contain credentials and business data. Apply the same storage/access policy as the source database. Set `HANOI_TEST_DATABASE_URL` to the verified restore before running `scripts/TEST_ALL.ps1`.

Phase 1 has no schema migration. Future migrations must be rehearsed on a disposable restore and reviewed for compatibility and lock impact. Production restore and traffic changes require their own approval.
