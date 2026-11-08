import { once } from 'node:events';
import type { AddressInfo } from 'node:net';
import type pg from 'pg';
import { expect, it, vi } from 'vitest';
import { createApp } from '../src/app.js';
import { EventHub } from '../src/events.js';
import { createShutdown } from '../src/shutdown.js';

function deferred() {
  let resolve!: () => void;
  const promise = new Promise<void>(done => { resolve = done; });
  return { promise, resolve };
}

it('drains an SSE stream and an in-flight database request before closing the pool', async () => {
  const hub = new EventHub();
  const started = deferred();
  const query = deferred();
  const pool = { query: () => { started.resolve(); return query.promise; } } as unknown as pg.Pool;
  const server = createApp(pool, hub, []).listen(0, '127.0.0.1');
  await once(server, 'listening');
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  const stopListener = vi.fn(async () => {});
  const closePool = vi.fn(async () => {});
  const stop = createShutdown(server, hub, stopListener, closePool, 5_000);

  try {
    const signal = AbortSignal.timeout(7000);
    const stream = await fetch(`${base}/api/events`, { headers: { Accept: 'text/event-stream' }, signal });
    const reader = stream.body!.pipeThrough(new TextDecoderStream()).getReader();
    expect((await reader.read()).value).toContain('{"type":"ready"}');
    const response = fetch(`${base}/api/health`, { headers: { Connection: 'close' }, signal });
    await started.promise;

    const shutDownStreams = once(hub, 'shutdown');
    const stopped = stop();
    expect(stop()).toBe(stopped);
    await shutDownStreams;
    expect(server.listening).toBe(false);
    expect(stopListener).toHaveBeenCalledTimes(1);
    expect(closePool).not.toHaveBeenCalled();

    let frames = '';
    for (let chunk = await reader.read(); !chunk.done; chunk = await reader.read()) frames += chunk.value;
    expect(frames).toBe('data: {"type":"reconnecting"}\n\n');
    for (const event of ['change', 'ready', 'offline', 'shutdown']) expect(hub.listenerCount(event)).toBe(0);

    query.resolve();
    const health = await response;
    expect(health.status).toBe(200);
    expect(await health.json()).toEqual({ status: 'ok', database: 'postgresql' });
    await stopped;
    expect(closePool).toHaveBeenCalledTimes(1);
  } finally {
    query.resolve();
    await stop();
  }
});

it('force-closes a socket at the end of the grace interval and closes dependencies once', async () => {
  const hub = new EventHub();
  const started = deferred();
  const query = deferred();
  const pool = { query: () => { started.resolve(); return query.promise; } } as unknown as pg.Pool;
  const server = createApp(pool, hub, []).listen(0, '127.0.0.1');
  await once(server, 'listening');
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  const force = vi.spyOn(server, 'closeAllConnections');
  const stopListener = vi.fn(async () => {});
  const closePool = vi.fn(async () => {});
  const stop = createShutdown(server, hub, stopListener, closePool, 25);
  try {
    const closed = fetch(`${base}/api/health`, { signal: AbortSignal.timeout(3000) })
      .then(() => false, () => true);
    await started.promise;
    await stop();
    expect(await closed).toBe(true);
    expect(force).toHaveBeenCalledTimes(1);
    expect(stopListener).toHaveBeenCalledTimes(1);
    expect(closePool).toHaveBeenCalledTimes(1);
  } finally {
    query.resolve();
    await stop();
  }
});
