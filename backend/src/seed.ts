import { readFile } from 'node:fs/promises';
import { pool } from './db.js';
import { hashPassword } from './security.js';
import { collections, parseRecord } from './validation.js';

const catalog = JSON.parse(await readFile('seed/catalog.json', 'utf8')) as Record<string, Record<string, unknown>[]>;
const connection = await pool.connect();
try {
  await connection.query('BEGIN');
  for (const table of collections) {
    for (const row of (catalog[table] ?? [])) {
      const { id, ...fields } = row;
      const data = { id, ...parseRecord(table, fields) };
      const keys = Object.keys(data);
      await connection.query(`INSERT INTO ${table}(${keys.join(',')}) VALUES(${keys.map((_, i) => `$${i+1}`).join(',')}) ON CONFLICT(id) DO NOTHING`, Object.values(data));
    }
  }
  // Seed static tables (not managed via SSE collections)
  for (const row of (catalog['emergency_contacts'] ?? [])) {
    const { id, ...rest } = row;
    const keys = ['id', ...Object.keys(rest)];
    const values = [id, ...Object.values(rest)];
    await connection.query(
      `INSERT INTO emergency_contacts(${keys.join(',')}) VALUES(${keys.map((_, i) => `$${i + 1}`).join(',')}) ON CONFLICT(id) DO NOTHING`,
      values
    );
  }
  if (process.env.ADMIN_EMAIL && process.env.ADMIN_PASSWORD) {
    await connection.query("INSERT INTO users(email,password_hash,role) VALUES($1,$2,'admin') ON CONFLICT(email) DO NOTHING", [process.env.ADMIN_EMAIL.toLowerCase(), await hashPassword(process.env.ADMIN_PASSWORD)]);
  }
  await connection.query('COMMIT');
  console.log('Seed ready: 5 places, 6 dishes/restaurants, 12 phrases, 6 events, 15 emergency contacts. Existing records preserved.');
} catch (error) { await connection.query('ROLLBACK'); throw error; }
finally { connection.release(); await pool.end(); }
