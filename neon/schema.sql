CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext UNIQUE NOT NULL,
  password_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS analysis_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  local_id text NOT NULL,
  analyzed_at timestamptz,
  image_path text,
  result jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, local_id)
);

CREATE TABLE IF NOT EXISTS food_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  local_id text NOT NULL,
  food_name text NOT NULL,
  consumed_at timestamptz NOT NULL,
  meal_type text NOT NULL,
  serving_size numeric NOT NULL DEFAULT 1,
  serving_unit text NOT NULL DEFAULT 'serving',
  calories integer NOT NULL DEFAULT 0,
  protein numeric NOT NULL DEFAULT 0,
  carbs numeric NOT NULL DEFAULT 0,
  fat numeric NOT NULL DEFAULT 0,
  sugar numeric NOT NULL DEFAULT 0,
  sodium numeric NOT NULL DEFAULT 0,
  fiber numeric NOT NULL DEFAULT 0,
  cost numeric NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'TWD',
  health_score integer NOT NULL DEFAULT 0,
  notes text NOT NULL DEFAULT '',
  source text NOT NULL DEFAULT 'manual',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, local_id)
);

CREATE INDEX IF NOT EXISTS idx_analysis_history_user_updated
  ON analysis_history (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_food_entries_user_consumed
  ON food_entries (user_id, consumed_at DESC);
