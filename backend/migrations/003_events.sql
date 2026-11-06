CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name_vi text NOT NULL CHECK(length(trim(name_vi)) > 0),
  name_en text NOT NULL CHECK(length(trim(name_en)) > 0),
  description_en text NOT NULL,
  event_date_start text NOT NULL DEFAULT '',
  event_date_end text NOT NULL DEFAULT '',
  is_recurring boolean NOT NULL DEFAULT false,
  recurrence_note text NOT NULL DEFAULT '',
  location_name text NOT NULL DEFAULT '',
  latitude double precision,
  longitude double precision,
  image_url text NOT NULL DEFAULT '',
  image_credit text NOT NULL DEFAULT '',
  source_url text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'touch_updated' AND tgrelid = 'events'::regclass) THEN
    EXECUTE 'CREATE TRIGGER touch_updated BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION touch_updated_at()';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'catalog_change' AND tgrelid = 'events'::regclass) THEN
    EXECUTE 'CREATE TRIGGER catalog_change AFTER INSERT OR UPDATE OR DELETE ON events FOR EACH STATEMENT EXECUTE FUNCTION notify_catalog_changed()';
  END IF;
END $$;
