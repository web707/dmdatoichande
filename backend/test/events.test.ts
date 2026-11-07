import 'dotenv/config';
import { afterAll, beforeAll, expect, it } from 'vitest';
import { once } from 'node:events';
import type { Server } from 'node:http';
import pg from 'pg';
import request from 'supertest';
import { EventHub, listenForChanges } from '../src/events.js';
import { createApp } from '../src/app.js';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const hub = new EventHub();
const app = createApp(pool, hub, ['http://localhost:8080']);
let server: Server;
let stop: () => Promise<void>;
beforeAll(async () => {
  const ready = once(hub, 'ready');
  stop = listenForChanges(process.env.DATABASE_URL!, hub);
  await ready;
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
});
afterAll(async () => { server.closeAllConnections(); server.close(); await stop(); await pool.end(); });
it('returns an events catalog as JSON when the client does not request SSE', async () => {
  const response = await request(app).get('/api/events').timeout({ deadline: 1500 });
  expect(response.status).toBe(200);
  expect(response.headers['content-type']).toContain('application/json');
  expect(Array.isArray(response.body)).toBe(true);
});
it('delivers committed PostgreSQL changes to two SSE clients without exposing content', async () => {
  const address = server.address() as { port: number };
  const abort = new AbortController();
  const readers = await Promise.all([1, 2].map(async () => {
    const response = await fetch(`http://127.0.0.1:${address.port}/api/events`, {
      signal: abort.signal,
      headers: { Accept: 'text/event-stream' },
    });
    expect(response.headers.get('content-type')).toContain('text/event-stream');
    const reader = response.body!.getReader();
    expect(new TextDecoder().decode((await reader.read()).value)).toContain('ready');
    return reader;
  }));
  const inserted = await pool.query("INSERT INTO phrases(vietnamese_text,english_meaning,pronunciation_guide,category) VALUES('SSE fixture','Test','test','other') RETURNING id");
  try {
    for (const reader of readers) {
      const message = new TextDecoder().decode((await reader.read()).value);
      expect(message).toContain('"table":"phrases"');
      expect(message).not.toContain('SSE fixture');
    }
    const received: string[] = [];
    const listener = (table: string) => received.push(table);
    hub.on('change', listener); hub.publish('users'); hub.publish('places');
    expect(received).toEqual(['places']); hub.off('change', listener);
    hub.emit('offline');
    for (const reader of readers) expect(new TextDecoder().decode((await reader.read()).value)).toContain('reconnecting');
  } finally { abort.abort(); await pool.query('DELETE FROM phrases WHERE id=$1', [inserted.rows[0].id]); }
});
it('does not notify rolled-back writes', async () => {
  const client = await pool.connect(); const received: string[] = [];
  const listener = (table: string) => received.push(table); hub.on('change', listener);
  try {
    await client.query('BEGIN');
    await client.query("INSERT INTO phrases(vietnamese_text,english_meaning,pronunciation_guide,category) VALUES('Rollback fixture','Test','test','other')");
    await client.query('ROLLBACK');
    await new Promise(resolve => setTimeout(resolve, 150)); expect(received).toEqual([]);
  } finally { hub.off('change', listener); client.release(); }
});
it('handles malformed JSON, excessive bodies and unknown endpoints', async () => {
  expect((await request(app).post('/api/auth/login').set('Content-Type', 'application/json').send('{')).status).toBe(400);
  expect((await request(app).post('/api/auth/login').send({ value: 'x'.repeat(70000) })).status).toBe(413);
  expect((await request(app).get('/api/not/an/endpoint')).status).toBe(404);
});
