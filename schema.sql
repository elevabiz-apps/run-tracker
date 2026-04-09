-- RunQuest - Schema para Supabase
-- Ejecutar en: Supabase Dashboard → SQL Editor

-- 1. TABLA: Estado del juego por usuario
CREATE TABLE IF NOT EXISTS user_game_state (
  user_id       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  xp            INTEGER DEFAULT 0,
  level         INTEGER DEFAULT 1,
  coins         INTEGER DEFAULT 0,
  streak        INTEGER DEFAULT 0,
  best_streak   INTEGER DEFAULT 0,
  shields       INTEGER DEFAULT 0,
  last_run_date DATE,
  record_dist   NUMERIC(6,2) DEFAULT 0,
  record_time   INTEGER DEFAULT 0,
  record_pace   NUMERIC(6,4),
  goal_time     INTEGER DEFAULT 20,
  shield_cost   INTEGER DEFAULT 15,
  penalty       INTEGER DEFAULT 2,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABLA: Carreras registradas
CREATE TABLE IF NOT EXISTS runs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  dist        NUMERIC(6,2) NOT NULL DEFAULT 0,
  time_min    INTEGER NOT NULL DEFAULT 0,
  xp_gained   INTEGER DEFAULT 0,
  met_goal    BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABLA: Recompensas configuradas por el usuario
CREATE TABLE IF NOT EXISTS rewards (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  cost        INTEGER NOT NULL,
  type        TEXT DEFAULT 'recurring' CHECK (type IN ('recurring', 'once')),
  redeemed    BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ===================== ROW LEVEL SECURITY =====================

ALTER TABLE user_game_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE runs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards          ENABLE ROW LEVEL SECURITY;

-- Cada usuario solo accede a sus propios datos
CREATE POLICY "own_game_state" ON user_game_state FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_runs"       ON runs             FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "own_rewards"    ON rewards          FOR ALL USING (auth.uid() = user_id);

-- ===================== TRIGGER: crear estado al registrarse =====================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_game_state (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
