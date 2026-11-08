import { existsSync } from 'node:fs';
import express, { type Express } from 'express';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const path = '/vr360/hoan-kiem';
const root = fileURLToPath(new URL('../vr360/', import.meta.url));
const vendor = fileURLToPath(new URL('../node_modules/pannellum/build/', import.meta.url));
const bundledData = fileURLToPath(new URL('../vr360/data/', import.meta.url));
const localData = fileURLToPath(new URL('../../.local/vr360/hoan-kiem/public/', import.meta.url));
const defaultData = existsSync(join(bundledData, 'tour.json')) ? bundledData : localData;

export function mountLakeTour(app: Express, data = defaultData, webOrigins: string[] = []) {
  const origins = webOrigins.filter(value => URL.canParse(value))
    .map(value => new URL(value).origin).filter(value => /^https?:\/\//.test(value));
  const frameAncestors = ["'self'", ...origins].join(' ');
  app.use(path, (_req, res, next) => {
    res.removeHeader('X-Frame-Options');
    res.set('Content-Security-Policy', [
      "default-src 'self'", "script-src 'self'", "style-src 'self' 'unsafe-inline'",
      "img-src 'self' blob: data:",
      "media-src 'self' blob: data:", "frame-src 'self' https: http: blob: data:", "base-uri 'none'", `frame-ancestors ${frameAncestors}`,
    ].join('; '));
    next();
  });
  app.use(`${path}/vendor`, express.static(vendor));
  app.use(`${path}/data/assets`, express.static(join(data, 'assets'), { immutable: true, maxAge: '1y' }));
  app.get(`${path}/data/tour.json`, (_req, res, next) => {
    res.sendFile('tour.json', { root: data }, error => {
      if (!error) return;
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') res.sendStatus(404);
      else next(error);
    });
  });
  app.use(path, express.static(root));
}
