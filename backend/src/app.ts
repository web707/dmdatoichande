import express, { type Request, type Response, type NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import { z } from 'zod';
import type pg from 'pg';
import { collectionSchema, credentialsSchema, parseRecord, uuidSchema } from './validation.js';
import { hashPassword, verifyPassword, newToken, tokenHash } from './security.js';
import type { EventHub } from './events.js';
import { createDestinationsRouter } from './destinations.js';
import { apiTelemetry } from './request-telemetry.js';

type User = { id: string; email: string; role: 'admin' | 'traveler' };
class HttpError extends Error { constructor(public status: number, message: string) { super(message); } }
const serviceUnavailable = 'Service is unavailable. Please try again.';
const sseFrame = (data: object) => `data: ${JSON.stringify(data)}\n\n`;
const reconnectingFrame = sseFrame({ type: 'reconnecting' });

export function createApp(pool: pg.Pool, hub: EventHub, origins: string[]) {
  const app = express();
  let databaseCheck: Promise<unknown> | undefined;
  const checkDatabase = () => {
    databaseCheck ??= pool.query('SELECT 1').finally(() => { databaseCheck = undefined; });
    return databaseCheck;
  };
  app.disable('x-powered-by');
  app.use('/api', apiTelemetry(process.env.API_LOG_REQUESTS === '1'));
  // Flutter's CanvasKit/WASM renderer needs a dedicated deployment CSP; keep API protections.
  app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false, crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use((req, _res, next) => {
    if (req.headers.origin && !origins.includes(req.headers.origin)) return next(new HttpError(403, 'Origin is not allowed.'));
    next();
  });
  app.use(cors({ origin: origins, exposedHeaders: ['Content-Type', 'X-Request-Id'] }));
  app.use((_req, res, next) => {
    if (!hub.isShuttingDown) return next();
    res.set('Connection', 'close');
    next(new HttpError(503, serviceUnavailable));
  });
  app.use(express.json({ limit: '64kb' }));
  app.use('/api', rateLimit({ windowMs: 60000, limit: 300, standardHeaders: 'draft-8', legacyHeaders: false, message: { error: 'Too many requests. Please try again shortly.' } }));
  const destinationPrefix = '/api/v1/destinations';
  app.use(destinationPrefix, (_req, res, next) => {
    res.locals.requestRoutePrefix = destinationPrefix;
    next();
  }, createDestinationsRouter(pool));
  app.get('/api/health', async (_req, res) => { await checkDatabase(); res.json({ status: 'ok', database: 'postgresql' }); });
  app.get('/api/live', (_req, res) => res.set('Cache-Control', 'no-store').json({ status: 'ok' }));
  app.get('/api/ready', async (_req, res) => {
    res.set('Cache-Control', 'no-store');
    await checkDatabase();
    res.json({ status: 'ok', database: 'postgresql' });
  });
  app.get('/api/events', (req, res, next) => {
    res.vary('Accept');
    // Regular catalog requests expect JSON. Live clients explicitly request SSE.
    if (req.accepts(['json', 'text/event-stream']) !== 'text/event-stream') return next();
    if (hub.isShuttingDown) throw new HttpError(503, serviceUnavailable);
    if (hub.listenerCount('change') >= 100) throw new HttpError(503, 'Too many live connections.');
    res.set({ 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache, no-transform', 'Connection': 'keep-alive', 'X-Accel-Buffering': 'no' });
    res.flushHeaders();
    const send = (frame: string) => {
      if (!res.destroyed && !res.writableEnded && !res.write(frame)) res.end();
    };
    const changed = (table: string) => send(sseFrame({ table }));
    const ready = () => send(sseFrame({ type: 'ready' }));
    const offline = () => send(reconnectingFrame);
    const heartbeat = setInterval(() => send(sseFrame({ type: 'heartbeat' })), 15000);
    function cleanup() {
      clearInterval(heartbeat);
      hub.off('change', changed);
      hub.off('ready', ready);
      hub.off('offline', offline);
      hub.off('shutdown', shutdown);
    }
    function shutdown() {
      cleanup();
      if (res.destroyed || res.writableEnded) return;
      const socket = res.socket;
      res.end(reconnectingFrame, () => socket?.end());
    }
    hub.on('change', changed);
    hub.on('ready', ready);
    hub.on('offline', offline);
    hub.on('shutdown', shutdown);
    res.once('close', cleanup);
    ready();
  });
  app.use('/api/auth', rateLimit({ windowMs: 60000, limit: 30, standardHeaders: 'draft-8', legacyHeaders: false, message: { error: 'Too many sign-in attempts. Try again in a minute.' } }));
  const issueSession = async (user: User, res: Response, status = 200) => {
    const token = newToken();
    await pool.query('DELETE FROM sessions WHERE expires_at < now()');
    await pool.query('INSERT INTO sessions(token_hash,user_id) VALUES($1,$2)', [tokenHash(token), user.id]);
    res.status(status).json({ token, user });
  };
  app.post('/api/auth/register', async (req, res) => {
    const credentials = credentialsSchema.parse(req.body);
    const result = await pool.query<User>('INSERT INTO users(email,password_hash) VALUES($1,$2) RETURNING id,email,role', [credentials.email, await hashPassword(credentials.password)]);
    await issueSession(result.rows[0], res, 201);
  });
  app.post('/api/auth/login', async (req, res) => {
    const credentials = credentialsSchema.parse(req.body);
    const result = await pool.query<User & { password_hash: string }>('SELECT id,email,role,password_hash FROM users WHERE email=$1', [credentials.email]);
    const user = result.rows[0];
    if (!user || !await verifyPassword(credentials.password, user.password_hash)) throw new HttpError(401, 'Email or password is incorrect.');
    await issueSession({ id: user.id, email: user.email, role: user.role }, res);
  });
  app.use('/api', async (req, res, next) => {
    const authorization = req.headers.authorization;
    if (authorization) {
      if (!/^Bearer [a-f0-9]{64}$/.test(authorization)) throw new HttpError(401, 'Please sign in again.');
      const digest = tokenHash(authorization.slice(7));
      const result = await pool.query<User>('SELECT u.id,u.email,u.role FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=$1 AND s.expires_at>now()', [digest]);
      if (!result.rows[0]) throw new HttpError(401, 'Please sign in again.');
      res.locals.user = result.rows[0]; res.locals.tokenHash = digest;
    }
    next();
  });
  const requireUser = (res: Response): User => { if (!res.locals.user) throw new HttpError(401, 'Please sign in to continue.'); return res.locals.user as User; };
  app.get('/api/auth/me', (_req, res) => res.json({ user: requireUser(res) }));
  app.post('/api/auth/logout', async (_req, res) => {
    requireUser(res); await pool.query('DELETE FROM sessions WHERE token_hash=$1', [res.locals.tokenHash]); res.sendStatus(204);
  });
  app.get('/api/emergency', async (_req, res) => {
    const result = await pool.query('SELECT * FROM emergency_contacts ORDER BY sort_order,category,id');
    res.json(result.rows);
  });
  app.get('/api/:collection', async (req, res) => {
    const parsed = collectionSchema.safeParse(req.params.collection);
    if (!parsed.success) throw new HttpError(404, 'Collection not found.');
    const table = parsed.data;
    const user = res.locals.user as User | undefined;
    const result = table === 'phrases'
      ? await pool.query('SELECT * FROM phrases WHERE owner_id IS NULL OR owner_id=$1 ORDER BY created_at,id', [user?.id ?? null])
      : await pool.query(`SELECT * FROM ${table} ORDER BY created_at,id`);
    res.json(result.rows);
  });
  for (const method of ['post', 'put', 'delete'] as const) {
    app[method](method === 'post' ? '/api/:collection' : '/api/:collection/:id', async (req, res) => {
      const table = collectionSchema.parse(req.params.collection);
      const user = requireUser(res);
      if (table !== 'phrases' && user.role !== 'admin') throw new HttpError(403, 'Administrator access is required.');
      const id = method === 'post' ? undefined : uuidSchema.parse((req.params as Record<string, string>).id);
      const data = method === 'delete' ? {} : parseRecord(table, req.body);
      const connection = await pool.connect();
      try {
        await connection.query('BEGIN');
        if (id) {
          const previous = table === 'phrases'
            ? await connection.query('SELECT * FROM phrases WHERE id=$1 AND (owner_id=$2 OR (owner_id IS NULL AND $3)) FOR UPDATE', [id, user.id, user.role === 'admin'])
            : await connection.query(`SELECT * FROM ${table} WHERE id=$1 FOR UPDATE`, [id]);
          if (!previous.rows[0]) throw new HttpError(404, 'Item no longer exists or is not accessible.');
        }
        if (method === 'delete') {
          await connection.query(`DELETE FROM ${table} WHERE id=$1`, [id]);
          await connection.query('COMMIT'); res.sendStatus(204); return;
        }
        if (table === 'phrases' && method === 'post') data.owner_id = user.role === 'admin' ? null : user.id;
        const keys = Object.keys(data); // Strict Zod schemas whitelist every SQL identifier.
        const values = Object.values(data);
        const result = method === 'post'
          ? await connection.query(`INSERT INTO ${table}(${keys.join(',')}) VALUES(${keys.map((_, i) => `$${i + 1}`).join(',')}) RETURNING *`, values)
          : await connection.query(`UPDATE ${table} SET ${keys.map((key, i) => `${key}=$${i + 1}`).join(',')} WHERE id=$${values.length + 1} RETURNING *`, [...values, id]);
        // One food key represents one dish; edits keep shared dish text consistent.
        if (table === 'foods_restaurants') await connection.query('UPDATE foods_restaurants SET food_name_vi=$1,food_name_en=$2,description_en=$3 WHERE food_key=$4 AND id<>$5', [data.food_name_vi, data.food_name_en, data.description_en, data.food_key, result.rows[0].id]);
        await connection.query('COMMIT');
        res.status(method === 'post' ? 201 : 200).json(result.rows[0]);
      } catch (error) { await connection.query('ROLLBACK'); throw error; }
      finally { connection.release(); }
    });
  }
  app.use('/api', (_req, _res, next) => next(new HttpError(404, 'Endpoint not found.')));
  app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (error instanceof z.ZodError) { res.status(400).json({ error: error.issues.map(issue => `${issue.path.join('.')}: ${issue.message}`).join('; ') }); return; }
    if (error instanceof HttpError) { res.status(error.status).json({ error: error.message }); return; }
    if (error instanceof URIError && (error as { status?: number }).status === 400) {
      res.status(400).json({ error: 'Invalid request path.' });
      return;
    }
    const code = (error as { code?: string }).code;
    if (code === '23505') { res.status(409).json({ error: 'This entry already exists.' }); return; }
    if (error instanceof SyntaxError) { res.status(400).json({ error: 'Invalid JSON body.' }); return; }
    if ((error as { status?: number }).status === 413) { res.status(413).json({ error: 'Request is too large.' }); return; }
    if (typeof code === 'string' && /^[0-9A-Z]{5}$/.test(code)) res.locals.databaseErrorCode = code;
    res.status(503).json({ error: serviceUnavailable });
  });
  return app;
}
