import { Router } from 'express';
import type pg from 'pg';
import { z } from 'zod';

const cursorSchema = z.string().length(64).transform(value => {
  const [createdAt, id] = value.split('~');
  return { createdAt, id };
}).pipe(z.object({
  createdAt: z.iso.datetime({ precision: 6 }).refine(value => !value.startsWith('0000'), 'Invalid cursor year'),
  id: z.guid(),
}));

const querySchema = z.object({
  limit: z.string().regex(/^[1-9]\d?$/).transform(Number).pipe(z.number().max(50)).default(20),
  cursor: cursorSchema.optional(),
  q: z.string().max(100).refine(value => !value.includes('\0'), 'Search term contains a null character').trim().default(''),
}).strict();

type DestinationSummary = {
  id: string;
  nameVi: string;
  nameEn: string;
  summaryEn: string;
  imageUrl: string;
  imageCredit: string;
  address: string;
};

type DestinationRow = DestinationSummary & { cursorCreatedAt: string };
type DestinationDetail = DestinationSummary & {
  historyEn: string;
  cultureEn: string;
  latitude: number;
  longitude: number;
  sourceUrl: string;
  openingHours: string;
  ticketPriceVnd: number;
  ticketPriceUsd: string;
  bookingInfo: string;
  visitDurationMin: number;
  bestTimeToVisit: string;
};

const summaryColumns = `id, name_vi AS "nameVi", name_en AS "nameEn", summary_en AS "summaryEn",
  image_url AS "imageUrl", image_credit AS "imageCredit", address`;

// Use Unicode case rules even when the database's default collation is C.
function normalizeSearch(expression: '$1::text' | 'name_vi' | 'name_en' | 'address') {
  return `btrim(regexp_replace(
    translate(regexp_replace(
      normalize(lower((${expression}) COLLATE pg_catalog.pg_unicode_fast), NFD),
      U&'[\\0300-\\036F]', '', 'g'
    ), 'đ', 'd'),
    '[[:space:]]+', ' ', 'g'
  ))`;
}

export function createDestinationsRouter(pool: pg.Pool) {
  const router = Router();
  router.get('/', async (req, res) => {
    const { limit, cursor, q } = querySchema.parse(req.query);
    const { rows } = await pool.query<DestinationRow>(`
      WITH search AS (SELECT ${normalizeSearch('$1::text')} AS needle)
      SELECT ${summaryColumns},
             to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "cursorCreatedAt"
      FROM places CROSS JOIN search
      WHERE (needle = ''
        OR strpos(${normalizeSearch('name_vi')}, needle) > 0
        OR strpos(${normalizeSearch('name_en')}, needle) > 0
        OR strpos(${normalizeSearch('address')}, needle) > 0)
        AND ($2::timestamptz IS NULL OR (created_at, id) > ($2::timestamptz, $3::uuid))
      ORDER BY created_at, id
      LIMIT $4
    `, [q, cursor?.createdAt ?? null, cursor?.id ?? null, limit + 1]);

    // Preserve PostgreSQL timestamp precision through the cursor, including ties within one millisecond.
    const last = rows[limit - 1];
    const nextCursor = rows.length > limit ? `${last.cursorCreatedAt}~${last.id}` : null;
    const items = rows.slice(0, limit).map(({ cursorCreatedAt, ...item }) => item);
    res.set('Cache-Control', 'public, no-cache').json({ items, nextCursor });
  });
  router.get('/:id', async (req, res) => {
    const id = z.guid().parse(req.params.id);
    const { rows } = await pool.query<DestinationDetail>(`
      SELECT ${summaryColumns}, history_en AS "historyEn", culture_en AS "cultureEn",
             latitude, longitude, source_url AS "sourceUrl", opening_hours AS "openingHours",
             ticket_price_vnd AS "ticketPriceVnd", ticket_price_usd::text AS "ticketPriceUsd",
             booking_info AS "bookingInfo", visit_duration_min AS "visitDurationMin",
             best_time_to_visit AS "bestTimeToVisit"
      FROM places
      WHERE id = $1::uuid
    `, [id]);
    const [destination] = rows;
    if (!destination) {
      res.status(404).json({ error: 'Destination not found.' });
      return;
    }
    res.set('Cache-Control', 'public, no-cache').json(destination);
  });
  return router;
}
