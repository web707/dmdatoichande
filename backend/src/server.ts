import express from 'express';
import { fileURLToPath } from 'node:url';
import { pool, databaseUrl } from './db.js';
import { createApp } from './app.js';
import { EventHub, listenForChanges } from './events.js';

const hub = new EventHub();
const app = createApp(pool, hub, (process.env.WEB_ORIGINS ?? 'http://localhost:8080,http://localhost:8090').split(','));
const webRoot = fileURLToPath(new URL('../../build/web/', import.meta.url));
app.use(express.static(webRoot));
app.get('/', (_req, res) => res.type('text').send('Hanoi Guide API is running. Build Flutter Web or run flutter run -d chrome --web-port=8080.'));
await pool.query('SELECT 1');
const stopListener = listenForChanges(databaseUrl, hub);
const server = app.listen(Number(process.env.PORT ?? 8090), process.env.HOST ?? '127.0.0.1', (error?: Error) => {
  if (error) {
    console.error('API could not bind its port:', error.message);
    void stopListener().then(() => pool.end());
    process.exitCode = 1;
    return;
  }
  console.log(`Hanoi Guide API ready on http://localhost:${process.env.PORT ?? 8090}`);
});
async function stop() {
  hub.emit('offline'); server.close(); server.closeAllConnections();
  await stopListener(); await pool.end();
}
process.once('SIGINT', () => void stop());
process.once('SIGTERM', () => void stop());
