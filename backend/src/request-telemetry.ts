import { randomUUID } from 'node:crypto';
import type { RequestHandler } from 'express';

const standardMethods = new Set(['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']);

export function apiTelemetry(logRequests: boolean): RequestHandler {
  return (req, res, next) => {
    const requestId = randomUUID();
    const start = performance.now();
    res.set('X-Request-Id', requestId);
    res.once('finish', () => {
      const status = res.statusCode;
      if (!logRequests && status < 500) return;

      const prefix = res.locals.requestRoutePrefix as string | undefined;
      const template = req.route?.path as unknown;
      const route = typeof template === 'string'
        ? (prefix ?? '') + (prefix && template === '/' ? '' : template)
        : 'unmatched';
      const entry = {
        event: 'api.request',
        requestId,
        method: standardMethods.has(req.method) ? req.method : 'OTHER',
        route,
        status,
        latencyMs: Math.round(performance.now() - start),
        errorCode: status >= 400 ? `HTTP_${status}` : null,
        ...(res.locals.databaseErrorCode ? { databaseErrorCode: res.locals.databaseErrorCode } : {}),
      };
      const line = JSON.stringify(entry);
      if (status >= 500) console.error(line);
      else console.info(line);
    });
    next();
  };
}
