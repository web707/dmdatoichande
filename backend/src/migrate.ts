import { readFile, readdir } from 'node:fs/promises';
import { pool } from './db.js';
const client = await pool.connect();
try {
  await client.query('CREATE TABLE IF NOT EXISTS schema_migrations(name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())');
  for (const name of (await readdir('migrations')).filter(name => name.endsWith('.sql')).sort()) {
    await client.query('BEGIN');
    await client.query("SELECT pg_advisory_xact_lock(hashtext('hanoi_guide_migrations'))");
    const existing = await client.query('SELECT 1 FROM schema_migrations WHERE name=$1', [name]);
    if (existing.rowCount === 0) {
      await client.query(await readFile(`migrations/${name}`, 'utf8'));
      await client.query('INSERT INTO schema_migrations(name) VALUES($1)', [name]);
      console.log(`Applied ${name}`);
    }
    await client.query('COMMIT');
  }
} catch (error) { await client.query('ROLLBACK'); throw error; }
finally { client.release(); await pool.end(); }
