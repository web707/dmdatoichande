CREATE TABLE IF NOT EXISTS emergency_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL CHECK(category IN ('police','fire','ambulance','hospital','pharmacy','embassy')),
  name_en text NOT NULL,
  name_vi text NOT NULL DEFAULT '',
  phone text NOT NULL DEFAULT '',
  address text NOT NULL DEFAULT '',
  latitude double precision,
  longitude double precision,
  country_code text NOT NULL DEFAULT '',
  note_en text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0
);
