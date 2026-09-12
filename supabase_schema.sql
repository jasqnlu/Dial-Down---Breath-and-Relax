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
-- SECURITY NOTE (updated 2026-07-06): Supabase Auth is now wired end-to-end
-- for Sign in with Apple — AuthManager exchanges the Apple identity token for
-- a Supabase session (SupabaseService.signInWithApple), persists/refreshes it
-- in the keychain, and attaches it as the Authorization bearer. All write
-- policies below therefore require `auth.uid()` to match the row's owner
-- column. Consequences:
--   • Guests and local email/Google accounts have NO Supabase session: they
--     can read public data but their uploads are rejected (the app treats
--     every upload as best-effort, so nothing breaks client-side).
--   • Rows written under the old anonymous-UUID scheme are orphaned — no
--     token can ever match them. Fine pre-launch; wipe the tables when
--     applying this version of the file.
--   • REQUIRED DASHBOARD STEP: enable the Apple provider under
--     Authentication → Providers, with the app's bundle ID as the client ID,
--     or every token exchange returns 4xx (the app then just stays local).
--
-- The `drop policy if exists` lines migrate a project that ran the previous
-- (anon-writable) version of this file; they no-op on a fresh project.

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

drop policy if exists "anyone can upsert routines" on routines;
drop policy if exists "anyone can update routines" on routines;
drop policy if exists "authors can insert their routines" on routines;
drop policy if exists "authors can update their routines" on routines;
drop policy if exists "authors can delete their routines" on routines;

-- Reconciled 2026-09-10 against the live project: the policies below (named
-- to match what's actually on the project) restore write access with
-- auth.uid() scoping. Client callers (SupabaseService.uploadRoutine() etc.)
-- do not exist yet — see TODO.md §3 "Restore write paths" — but the RLS
-- side is ready for when they're added.

create policy "public routines are readable by anyone"
  on routines for select
  using (is_public = true);

create policy "Users can read public routines or their own"
  on routines for select
  using (is_public = true or auth.uid()::text = author_id);

create policy "Users can insert their own routines"
  on routines for insert
  with check (auth.uid()::text = author_id);

create policy "Users can update their own routines"
  on routines for update
  using (auth.uid()::text = author_id);

create policy "Users can delete their own routines"
  on routines for delete
  using (auth.uid()::text = author_id);

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

drop policy if exists "anyone can insert sessions" on sessions;
drop policy if exists "users can insert their sessions" on sessions;

-- Reconciled 2026-09-10 against the live project: write/read policies below
-- (named to match the live project) are already applied server-side, ahead
-- of the client write path — see TODO.md §3 "Restore write paths".

create policy "Users can insert their own sessions"
  on sessions for insert
  with check (auth.uid()::text = user_id);

create policy "Users can read their own sessions"
  on sessions for select
  using (auth.uid()::text = user_id);

create policy "Users can update their own sessions"
  on sessions for update
  using (auth.uid()::text = user_id);

create policy "Users can delete their own sessions"
  on sessions for delete
  using (auth.uid()::text = user_id);

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

drop policy if exists "anyone can upsert their profile" on profiles;
drop policy if exists "anyone can update profiles" on profiles;
drop policy if exists "anyone can delete a profile by id" on profiles;
drop policy if exists "users can insert their profile" on profiles;
drop policy if exists "users can update their profile" on profiles;
drop policy if exists "users can delete their profile" on profiles;

create policy "users can insert their profile"
  on profiles for insert
  with check (auth.uid() is not null and id = auth.uid()::text);

create policy "users can update their profile"
  on profiles for update
  using (auth.uid() is not null and id = auth.uid()::text)
  with check (auth.uid() is not null and id = auth.uid()::text);

-- Delete Account flow (AuthManager.deleteAccount → SupabaseService
-- .deleteProfile) removes the leaderboard row *before* revoking the session,
-- so the token still authorizes this policy at that moment.
create policy "users can delete their profile"
  on profiles for delete
  using (auth.uid() is not null and id = auth.uid()::text);

-- ───────────────────────── profiles (additions) ─────────────────────────
-- Added 2026-09-12 for streak-about-to-break push notifications. Best-effort
-- upload from SessionRecorder.record() on every completed session.
alter table profiles add column if not exists last_session_at timestamptz;

-- ───────────────────────── push_tokens ─────────────────────────
-- One row per signed-in device. Not publicly readable — only the service
-- role (used exclusively by the send-streak-warnings Edge Function) ever
-- reads this table; RLS still lets an owner manage their own row directly
-- for register/unregister, matching every other write path in this file.

create table if not exists push_tokens (
  user_id         text primary key check (char_length(user_id) <= 40), -- auth.uid(), matches profiles.id
  device_token    text not null check (char_length(device_token) <= 200),
  timezone        text not null default 'UTC' check (char_length(timezone) <= 64), -- IANA name, e.g. "America/Los_Angeles"
  last_warned_date date, -- last local calendar date this user was sent a streak-risk push; prevents double-send
  updated_at      timestamptz not null default now()
);

alter table push_tokens enable row level security;

create policy "users can upsert their own push token"
  on push_tokens for insert
  with check (auth.uid()::text = user_id);

create policy "users can update their own push token"
  on push_tokens for update
  using (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

create policy "users can delete their own push token"
  on push_tokens for delete
  using (auth.uid()::text = user_id);

-- No select policy: nobody needs to read this back through the client API.
-- The Edge Function reads it via the service role, which bypasses RLS.

-- ───────────────────────── get_streak_warning_candidates() ─────────────────────────
-- Per-row IANA-timezone math lives here (not in the Edge Function) because
-- Postgres's `at time zone` handles DST correctly and PostgREST filters
-- can't express "local hour is 20" across arbitrary timezones in one call.
-- security definer + a locked-down search_path so it's safe to run with the
-- privileges of whoever created it (the migration, effectively postgres);
-- execute is revoked from everyone except service_role below, so only the
-- Edge Function (which authenticates as service_role) can call it.
create or replace function get_streak_warning_candidates()
returns table (
  user_id      text,
  device_token text,
  timezone     text
)
language sql
security definer
set search_path = public
as $$
  select pt.user_id, pt.device_token, pt.timezone
  from push_tokens pt
  join profiles pr on pr.id = pt.user_id
  where pr.streak >= 2
    and extract(hour from (now() at time zone pt.timezone)) = 20
    and (
      pr.last_session_at is null
      or pr.last_session_at < date_trunc('day', now() at time zone pt.timezone) at time zone pt.timezone
    )
    and (
      pt.last_warned_date is null
      or pt.last_warned_date <> (now() at time zone pt.timezone)::date
    )
$$;

revoke all on function get_streak_warning_candidates() from public;
grant execute on function get_streak_warning_candidates() to service_role;
