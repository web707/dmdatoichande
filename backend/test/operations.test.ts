import { once } from 'node:events';
import type pg from 'pg';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createApp } from '../src/app.js';
import { EventHub } from '../src/events.js';

const query = vi.fn();
const allowedOrigin = 'http://localhost:8080';
const app = () => createApp({ query } as unknown as pg.Pool, new EventHub(), [allowedOrigin]);
const requestIdPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

describe('API operational endpoints and logs', () => {
  beforeEach(() => {
    query.mockReset();
    vi.stubEnv('API_LOG_REQUESTS', '0');
  });
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
  });

  it('checks liveness without contacting PostgreSQL or logging a routine success', async () => {
    const log = vi.spyOn(console, 'info').mockImplementation(() => {});
    const response = await request(app()).get('/api/live').set('X-Request-Id', 'untrusted-id');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
    expect(response.headers['cache-control']).toBe('no-store');
    expect(response.headers['x-request-id']).toMatch(requestIdPattern);
    expect(query).not.toHaveBeenCalled();
    expect(log).not.toHaveBeenCalled();
  });

  it('shares an in-flight database probe between readiness and legacy health', async () => {
    let finishQuery!: () => void;
    query.mockReturnValue(new Promise<void>(resolve => { finishQuery = resolve; }));
    const server = app().listen(0, '127.0.0.1');
    await once(server, 'listening');
    const arrived = new Promise<void>(resolve => {
      let count = 0;
      server.on('request', () => { if (++count === 2) resolve(); });
    });
    const responses = Promise.all([
      request(server).get('/api/ready'),
      request(server).get('/api/health'),
    ]);
    try {
      await arrived;
      expect(query).toHaveBeenCalledExactlyOnceWith('SELECT 1');
    } finally {
      finishQuery();
      try {
        await responses;
      } finally {
        await new Promise<void>(resolve => { server.close(() => resolve()); });
      }
    }
    for (const response of await responses) {
      expect(response.status).toBe(200);
      expect(response.body).toEqual({ status: 'ok', database: 'postgresql' });
    }
  });

  it('correlates an unavailable database with a redacted 503 log and recovers', async () => {
    const log = vi.spyOn(console, 'error').mockImplementation(() => {});
    query
      .mockRejectedValueOnce(Object.assign(new Error('postgres://private-user:secret@localhost/database'), { code: '08006' }))
      .mockResolvedValueOnce({ rows: [] });
    const api = app();
    const unavailable = await request(api).get('/api/ready?secret=internal-value');
    expect(unavailable.status).toBe(503);
    expect(unavailable.body).toEqual({ error: 'Service is unavailable. Please try again.' });
    const line = log.mock.calls[0][0];
    expect(JSON.parse(line)).toMatchObject({
      event: 'api.request',
      requestId: unavailable.headers['x-request-id'],
      method: 'GET',
      route: '/api/ready',
      status: 503,
      errorCode: 'HTTP_503',
      databaseErrorCode: '08006',
      latencyMs: expect.any(Number),
    });
    expect(line).not.toContain('secret');
    expect(line).not.toContain('internal-value');
    expect((await request(api).get('/api/ready')).status).toBe(200);
  });

  it('exposes a server request ID and logs only route templates in diagnostic mode', async () => {
    vi.stubEnv('API_LOG_REQUESTS', '1');
    const log = vi.spyOn(console, 'info').mockImplementation(() => {});
    query.mockResolvedValue({ rows: [] });
    const api = app();
    const response = await request(api).get('/api/v1/destinations?q=private-search')
      .set('Origin', allowedOrigin)
      .set('X-Request-Id', 'private-header')
      .set('Authorization', 'Bearer private-token');
    expect(response.status).toBe(200);
    expect(response.headers['access-control-expose-headers']).toContain('X-Request-Id');
    expect(response.headers['x-request-id']).toMatch(requestIdPattern);
    expect(JSON.parse(log.mock.calls[0][0])).toMatchObject({
      requestId: response.headers['x-request-id'],
      route: '/api/v1/destinations',
      status: 200,
      errorCode: null,
    });
    expect(log.mock.calls[0][0]).not.toContain('private');

    const denied = await request(api).get('/api/secret-value').set('Origin', 'https://invalid.example');
    expect(denied.status).toBe(403);
    expect(denied.headers['x-request-id']).toMatch(requestIdPattern);
    expect(JSON.parse(log.mock.calls[1][0])).toMatchObject({
      requestId: denied.headers['x-request-id'],
      route: 'unmatched',
      status: 403,
      errorCode: 'HTTP_403',
    });
  });

  it('rejects malformed percent escapes without echoing the request path', async () => {
    const response = await request(app()).get('/api/v1/destinations/%E0%A4%A');
    expect(response.status).toBe(400);
    expect(response.body).toEqual({ error: 'Invalid request path.' });
    expect(query).not.toHaveBeenCalled();
  });
});
