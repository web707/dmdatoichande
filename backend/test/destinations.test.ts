import { readFileSync } from 'node:fs';
import type pg from 'pg';
import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { createApp } from '../src/app.js';
import { EventHub } from '../src/events.js';

const spec = JSON.parse(readFileSync(
  new URL('../../hanoi-guide-contracts/openapi/destinations-v1.json', import.meta.url),
  'utf8',
));
const { DestinationSummary, DestinationPage, ApiError } = spec.components.schemas;
const endpoint = Object.keys(spec.paths)[0];
const id = '10000000-0000-4000-8000-000000000001';
const row = {
  id, nameVi: 'Hồ Hoàn Kiếm', nameEn: 'Hoan Kiem Lake', summaryEn: 'Summary',
  imageUrl: 'https://example.org/lake.jpg', imageCredit: 'Photographer', address: 'Hanoi',
  cursorCreatedAt: '2026-11-08T12:00:00.123456Z',
};
const query = vi.fn();
const app = createApp({ query } as unknown as pg.Pool, new EventHub(), ['http://localhost:8080']);

describe('destination API contract', () => {
  beforeEach(() => query.mockReset());

  it('returns only contract fields and uses the final returned row as the cursor', async () => {
    query.mockResolvedValue({ rows: [row, { ...row, id: '10000000-0000-4000-8000-000000000002' }] });
    const response = await request(app).get(endpoint).query({ limit: 1, q: '  Hồ  ' });
    expect(response.status).toBe(200);
    expect(Object.keys(response.body).sort()).toEqual([...DestinationPage.required].sort());
    expect(response.body.items).toHaveLength(1);
    const [item] = response.body.items;
    expect(Object.keys(item).sort()).toEqual([...DestinationSummary.required].sort());
    for (const key of DestinationSummary.required) expect(typeof item[key]).toBe('string');
    expect(item.id).toBe(id);
    expect(response.body.nextCursor).toBe(`${row.cursorCreatedAt}~${id}`);
    expect(query).toHaveBeenCalledExactlyOnceWith(expect.stringContaining('LIMIT $4'), ['Hồ', null, null, 2]);

    query.mockResolvedValue({ rows: [] });
    const next = await request(app).get(endpoint).query({ cursor: response.body.nextCursor, q: 'Hồ' });
    expect(next.status).toBe(200);
    expect(next.body).toEqual({ items: [], nextCursor: null });
    expect(query).toHaveBeenLastCalledWith(expect.any(String), ['Hồ', row.cursorCreatedAt, id, 21]);
  });

  it('supports conditional requests for the public response', async () => {
    query.mockResolvedValue({ rows: [row] });
    const first = await request(app).get(endpoint);
    expect(first.headers['cache-control']).toBe('public, no-cache');
    expect(first.headers.etag).toBeTruthy();
    expect(first.body.nextCursor).toBeNull();
    const second = await request(app).get(endpoint).set('If-None-Match', first.headers.etag);
    expect(second.status).toBe(304);
    expect(second.text).toBe('');
  });

  it.each([
    '?limit=51', '?limit=0', '?limit=1.5', '?limit=1&limit=2', '?cursor=broken',
    `?cursor=2026-02-31T12:00:00.123456Z~${id}`,
    `?cursor=0000-01-01T12:00:00.123456Z~${id}`,
    `?q=${'a'.repeat(101)}`, '?q=%00',
  ])('rejects invalid input before querying PostgreSQL (%s)', async search => {
    const response = await request(app).get(endpoint + search);
    expect(response.status).toBe(400);
    expect(Object.keys(response.body)).toEqual(ApiError.required);
    expect(typeof response.body.error).toBe('string');
    expect(query).not.toHaveBeenCalled();
  });
});
