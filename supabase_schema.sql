-- Breath: Relax & Stretch — Supabase schema
--
-- Paste this whole file into Supabase Dashboard → SQL Editor → New query → Run.
-- Creates all four tables the app talks to (SupabaseService.swift) plus RLS
-- policies, in one shot. After running this, just copy your Project URL and
-- anon key from Dashboard → Settings → API into SupabaseService.swift.
--
-- SECURITY NOTE: AuthManager (this app's sign-in) is fully local/keychain-based
-- and is NOT wired to Supabase Auth — every request the app makes uses the
-- anon key, never a per-user Supabase session token. The policies below are
-- written to match that reality (anon can read/write within the documented
-- shape) rather than pretending there's row-level user isolation that doesn't
-- exist yet. If you later wire AuthManager.signIn into
-- SupabaseService.signInWithApple(identityToken:) (already written, just
-- unused) you can tighten these to `auth.uid() = author_id`-style checks.

-- ───────────────────────── exercises ─────────────────────────
-- Public, read-only catalog. The app falls back to its bundled SeedData.json
-- when this is empty or unreachable, so this table is optional — only needed
-- if you want to push catalog updates without an App Store release.

create table if not exists exercises (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null,
  type               text not null,             -- 'stretch' | 'breath' | 'both'
  target_body_parts  text[] not null default '{}',
  duration_seconds   int4 not null,
  difficulty         int4 not null,              -- 1=easy, 2=medium, 3=hard
  instructions       text[] not null default '{}',
  media_url          text,
  caution            text
);

alter table exercises enable row level security;

create policy "exercises are publicly readable"
  on exercises for select
  using (true);

-- ───────────────────────── routines ─────────────────────────
-- User-created routines. is_public = true ones show up in BorrowRoutineView.

create table if not exists routines (
  id                 uuid primary key,
  name               text not null,
  exercise_ids       text[] not null default '{}',
  author_id          text,                       -- user's email (see security note above)
  author_name        text,
  borrowed_from_id   text,
  is_public          bool not null default false,
  borrow_count       int4 not null default 0
);

alter table routines enable row level security;

create policy "public routines are readable by anyone"
  on routines for select
  using (is_public = true);

create policy "anyone can upsert routines"
  on routines for insert
  with check (true);

create policy "anyone can update routines"
  on routines for update
  using (true);

-- ───────────────────────── sessions ─────────────────────────
-- Completed session history, one row per session, uploaded best-effort.

create table if not exists sessions (
  id                  uuid primary key,
  user_id             text not null,             -- user's email
  routine_id          text not null,
  started_at          timestamptz not null,
  completed_at        timestamptz,
  completion_percent  float8 not null,
  points_earned       int4 not null
);

alter table sessions enable row level security;

create policy "anyone can insert sessions"
  on sessions for insert
  with check (true);

-- No public select policy — session history isn't read back from Supabase
-- today (SwiftData is the source of truth on-device). Add one later if you
-- build cross-device session sync.

-- ───────────────────────── profiles ─────────────────────────
-- Public leaderboard rows — only points/streak/minutes/display name, no email.

create table if not exists profiles (
  id             text primary key,               -- user's email, used only as a dedupe key
  display_name   text not null default '',
  total_points   int4 not null default 0,
  streak         int4 not null default 0,
  total_minutes  int4 not null default 0
);

alter table profiles enable row level security;

create policy "profiles are publicly readable"
  on profiles for select
  using (true);

create policy "anyone can upsert their profile"
  on profiles for insert
  with check (true);

create policy "anyone can update profiles"
  on profiles for update
  using (true);
