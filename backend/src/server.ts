import express from 'express';
import { fileURLToPath } from 'node:url';
import { pool, databaseUrl } from './db.js';
import { createApp } from './app.js';
import { EventHub, listenForChanges } from './events.js';
import { createShutdown, httpDrainMs } from './shutdown.js';
import { mountLakeTour } from './vr360.js';

const hub = new EventHub();
const origins = (process.env.WEB_ORIGINS ?? 'http://localhost:8080,http://localhost:8090').split(',');
const app = createApp(pool, hub, origins);
mountLakeTour(app, undefined, origins);
const webRoot = fileURLToPath(new URL('../../build/web/', import.meta.url));
app.use(express.static(webRoot));
app.get('/', (_req, res) => res.type('text').send('Hanoi Guide API is running. Build Flutter Web or run flutter run -d chrome --web-port=8080.'));
await pool.query('SELECT 1');
const stopListener = listenForChanges(databaseUrl, hub);
const server = app.listen(Number(process.env.PORT ?? 8090), process.env.HOST ?? '127.0.0.1', (error?: Error) => {
  if (error) {
    console.error('API could not bind its port:', error.message);
    process.exitCode = 1;
    stop();
    return;
  }
  console.log(`Hanoi Guide API ready on http://localhost:${process.env.PORT ?? 8090}`);
});
const shutdown = createShutdown(server, hub, stopListener, () => pool.end());
let stopping = false;
function stop() {
  if (stopping) return;
  stopping = true;
  // An unresponsive database connection cannot hold the process open indefinitely.
  const deadline = setTimeout(() => {
    console.error('API shutdown exceeded its deadline.');
    process.exit(1);
  }, httpDrainMs + 5_000).unref();
  void shutdown().catch(() => {
    console.error('API resources could not be closed cleanly.');
    process.exitCode = 1;
  }).finally(() => clearTimeout(deadline));
}
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
