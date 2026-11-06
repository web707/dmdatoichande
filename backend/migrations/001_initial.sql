CREATE TABLE IF NOT EXISTS users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), email text NOT NULL UNIQUE,
 password_hash text NOT NULL, role text NOT NULL DEFAULT 'traveler' CHECK(role IN ('admin','traveler')),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS sessions (
 token_hash text PRIMARY KEY, user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 expires_at timestamptz NOT NULL DEFAULT now() + interval '7 days'
);
CREATE INDEX IF NOT EXISTS sessions_expiry ON sessions(expires_at);
CREATE TABLE IF NOT EXISTS places (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name_vi text NOT NULL CHECK(length(trim(name_vi))>0), name_en text NOT NULL,
 summary_en text NOT NULL, history_en text NOT NULL, culture_en text NOT NULL,
 image_url text NOT NULL, image_credit text NOT NULL, address text NOT NULL,
 latitude double precision NOT NULL CHECK(latitude BETWEEN -90 AND 90), longitude double precision NOT NULL CHECK(longitude BETWEEN -180 AND 180),
 source_url text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS phrases (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), vietnamese_text text NOT NULL CHECK(length(trim(vietnamese_text))>0), english_meaning text NOT NULL,
 pronunciation_guide text NOT NULL, ipa text NOT NULL DEFAULT '', category text NOT NULL CHECK(category IN ('greetings','shopping','food','directions','other')),
 usage_note_en text NOT NULL DEFAULT '', owner_id uuid REFERENCES users(id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS phrases_owner ON phrases(owner_id);
CREATE TABLE IF NOT EXISTS foods_restaurants (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), food_key text NOT NULL, food_name_vi text NOT NULL,
 food_name_en text NOT NULL, description_en text NOT NULL, restaurant_name text NOT NULL, address text NOT NULL,
 latitude double precision NOT NULL CHECK(latitude BETWEEN -90 AND 90), longitude double precision NOT NULL CHECK(longitude BETWEEN -180 AND 180),
 image_url text NOT NULL DEFAULT '', image_credit text NOT NULL DEFAULT '', source_url text NOT NULL DEFAULT '',
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS foods_group ON foods_restaurants(food_key);
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at=clock_timestamp(); RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION notify_catalog_changed() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN PERFORM pg_notify('catalog_changed', TG_TABLE_NAME); RETURN NULL; END $$;
DO $$ DECLARE tab text; BEGIN
 FOREACH tab IN ARRAY ARRAY['places','phrases','foods_restaurants'] LOOP
  EXECUTE format('CREATE TRIGGER touch_updated BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION touch_updated_at()', tab);
  EXECUTE format('CREATE TRIGGER catalog_change AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH STATEMENT EXECUTE FUNCTION notify_catalog_changed()', tab);
 END LOOP;
END $$;
