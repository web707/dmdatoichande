import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterAll, beforeAll, expect, it } from 'vitest';
import express from 'express';
import request from 'supertest';
import { mountLakeTour } from '../src/vr360.js';

const base = '/vr360/hoan-kiem';
const app = express();
let root: string;

beforeAll(async () => {
  root = await mkdtemp(join(tmpdir(), 'hanoi-lake-tour-'));
  const publicDir = join(root, '.local', 'public');
  await mkdir(join(publicDir, 'assets'), { recursive: true });
  await writeFile(join(root, 'source.js'), 'private archive');
  await writeFile(join(publicDir, 'tour.json'), '{"firstScene":"9861"}');
  await writeFile(join(publicDir, 'assets', 'scene-123.webp'), 'fixture');
  mountLakeTour(app, publicDir);
});

afterAll(async () => {
  if (root) await rm(root, { recursive: true, force: true });
});

it('serves the local tour and leaves the manifest revalidatable', async () => {
  const html = await request(app).get(`${base}/index.html`).expect(200);
  expect(html.text).toContain('pannellum.js');
  const manifest = await request(app).get(`${base}/data/tour.json`).expect(200);
  expect(manifest.body.firstScene).toBe('9861');
  expect(manifest.headers['cache-control']).not.toContain('immutable');
});

it('caches versioned images and keeps the upstream archive private', async () => {
  const image = await request(app).get(`${base}/data/assets/scene-123.webp`).expect(200);
  expect(image.headers['cache-control']).toContain('immutable');
  await request(app).get(`${base}/data/source.js`).expect(404);
});
