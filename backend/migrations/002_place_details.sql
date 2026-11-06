ALTER TABLE places ADD COLUMN IF NOT EXISTS opening_hours text NOT NULL DEFAULT '';
ALTER TABLE places ADD COLUMN IF NOT EXISTS ticket_price_vnd integer NOT NULL DEFAULT 0;
ALTER TABLE places ADD COLUMN IF NOT EXISTS ticket_price_usd numeric(6,2) NOT NULL DEFAULT 0;
ALTER TABLE places ADD COLUMN IF NOT EXISTS booking_info text NOT NULL DEFAULT '';
ALTER TABLE places ADD COLUMN IF NOT EXISTS visit_duration_min integer NOT NULL DEFAULT 0;
ALTER TABLE places ADD COLUMN IF NOT EXISTS best_time_to_visit text NOT NULL DEFAULT '';

UPDATE places SET
  opening_hours = 'Open 24 hours. Ngoc Son Temple: Tuesday–Sunday 08:00–18:00.',
  ticket_price_vnd = 0,
  ticket_price_usd = 0,
  booking_info = 'No booking required for the lake promenade (always free). Ngoc Son Temple on the island charges 30,000 VND, payable at the gate.',
  visit_duration_min = 60,
  best_time_to_visit = 'Early morning (06:00–08:00) for locals'' exercise routines, or dusk (17:30–19:00) for the lit-up bridge. Weekends are livelier but more crowded.'
WHERE id = '10000000-0000-4000-8000-000000000001';

UPDATE places SET
  opening_hours = 'Tuesday–Sunday 08:00–17:00. Closed Mondays.',
  ticket_price_vnd = 70000,
  ticket_price_usd = 2.80,
  booking_info = 'Tickets sold at the main gate (58 Quoc Tu Giam). No advance booking required for individuals. Group bookings (10+ people) can be arranged through the heritage centre office.',
  visit_duration_min = 90,
  best_time_to_visit = 'Weekday mornings (08:00–10:00) are quietest. Avoid Sunday afternoons during school holidays. Mid-morning light is best for photographs.'
WHERE id = '10000000-0000-4000-8000-000000000002';
