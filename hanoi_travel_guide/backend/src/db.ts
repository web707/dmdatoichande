import 'dotenv/config';
import pg from 'pg';
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is missing. Run scripts/setup-local.ps1 first.');
export const databaseUrl = process.env.DATABASE_URL;
export const pool = new pg.Pool({ connectionString: databaseUrl, max: 10, connectionTimeoutMillis: 5000, statement_timeout: 10000 });
pool.on('error', () => console.error('An idle database connection was lost.'));
