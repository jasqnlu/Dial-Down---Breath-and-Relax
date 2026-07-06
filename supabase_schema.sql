-- Breath: Relax & Stretch — Supabase schema
--
-- Paste this whole file into Supabase Dashboard → SQL Editor → New query → Run.
-- Creates all four tables the app talks to (SupabaseService.swift) plus RLS
-- policies, in one shot. After running this, just copy your Project URL and
-- anon key from Dashboard → Settings → API into SupabaseService.swift.
--
-- IDENTITY NOTE: the app identifies users by an anonymous per-install UUID
-- (AuthManager.anonymousID) — author_id / user_id / profiles.id are opaque
-- UUIDs. Emails are NEVER sent to these tables; several of them are publicly
-- readable, so treat every column here as public data.
--
-- SECURITY NOTE — READ BEFORE LAUNCH: AuthManager (this app's sign-in) is
-- fully local/keychain-based and is NOT wired to Supabase Auth — every request
-- the app makes uses the anon key, never a per-user Supabase session token.
-- The write policies below are therefore anon-writable: anyone who extracts
-- the anon key from the binary can insert/update rows (spoof leaderboard
-- scores, edit others' public routines). The check constraints limit the
-- blast radius (no megabyte payloads, no absurd values) but do NOT provide
-- per-user isolation. Before shipping the community features publicly, wire
-- AuthManager into SupabaseService.signInWithApple(identityToken:) (already
-- written, just unused) and tighten these to `auth.uid()`-based checks — or
-- keep the community features hidden (the app already gates them behind
-- SupabaseService.isConfigured).

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

-- No insert/update policy: the catalog is maintained from the dashboard
-- (service role), never by app clients.

-- ───────────────────────── routines ─────────────────────────
-- User-created routines. is_public = true ones show up in BorrowRoutineView.

create table if not exists routines (
  id                 uuid primary key,
  name               text not null check (char_length(name) <= 80),
  exercise_ids       text[] not null default '{}' check (array_length(exercise_ids, 1) <= 50),
  author_id          text check (char_length(author_id) <= 40),   -- anonymous UUID, never an email
  author_name        text check (char_length(author_name) <= 80),
  borrowed_from_id   text check (char_length(borrowed_from_id) <= 40),
  is_public          bool not null default false,
  borrow_count       int4 not null default 0 check (borrow_count between 0 and 1000000)
);

alter table routines enable row level security;

create policy "public routines are readable by anyone"
  on routines for select
  using (is_public = true);

-- ⚠️ anon-writable until Supabase Auth is wired in (see security note above).
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
  user_id             text not null check (char_length(user_id) <= 40),  -- anonymous UUID, never an email
  routine_id          text not null check (char_length(routine_id) <= 40),
  started_at          timestamptz not null,
  completed_at        timestamptz,
  completion_percent  float8 not null check (completion_percent between 0 and 100),
  points_earned       int4 not null check (points_earned between 0 and 100000)
);

alter table sessions enable row level security;

-- ⚠️ anon-writable until Supabase Auth is wired in (see security note above).
create policy "anyone can insert sessions"
  on sessions for insert
  with check (true);

-- No public select policy — session history isn't read back from Supabase
-- today (SwiftData is the source of truth on-device). Add one later if you
-- build cross-device session sync.

-- ───────────────────────── profiles ─────────────────────────
-- Public leaderboard rows — only points/streak/minutes/display name.
-- id is the anonymous per-install UUID; emails never reach this table.

create table if not exists profiles (
  id             text primary key check (char_length(id) <= 40),
  display_name   text not null default '' check (char_length(display_name) <= 80),
  total_points   int4 not null default 0 check (total_points between 0 and 100000000),
  streak         int4 not null default 0 check (streak between 0 and 100000),
  total_minutes  int4 not null default 0 check (total_minutes between 0 and 100000000)
);

alter table profiles enable row level security;

create policy "profiles are publicly readable"
  on profiles for select
  using (true);

-- ⚠️ anon-writable until Supabase Auth is wired in (see security note above).
create policy "anyone can upsert their profile"
  on profiles for insert
  with check (true);

create policy "anyone can update profiles"
  on profiles for update
  using (true);

-- ⚠️ anon-deletable, same caveat as the write policies above. Needed so the
-- app's Delete Account flow (AuthManager.deleteAccount →
-- SupabaseService.deleteProfile) can remove the public leaderboard row before
-- the anonymous ID is rotated; deletion requires knowing the full UUID.
-- Tighten to auth.uid() alongside the other policies when Supabase Auth lands.
create policy "anyone can delete a profile by id"
  on profiles for delete
  using (true);
