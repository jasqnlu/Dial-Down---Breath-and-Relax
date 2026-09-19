# Streak-about-to-break push notifications — design

## Motivation

The app already reminds users locally (`NotificationService.swift`, a plain
`UNUserNotificationCenter` calendar-trigger notification at a user-picked
hour). That's fully client-side and already works. This spec adds a second,
server-triggered notification: if a user has a meaningful streak going and
hasn't done a session yet today, ping them in the evening before it breaks
at midnight. This requires a real backend trigger — the device can't know
on its own, ahead of time, whether "today" is going to end without a
session — so it needs APNs, a stored device token, and something server-side
that periodically checks.

## Scope

**In scope:** one notification type — streak-about-to-break, one push per
user per local day, gated behind the same `notificationsEnabled` toggle the
local reminder already uses.

**Out of scope (explicitly deferred):**
- Any other push type (challenges, social, marketing). This spec builds the
  minimum pipeline for one trigger; a second trigger later reuses the same
  device-token infrastructure but is its own future spec.
- Live Activities (unrelated feature, uses a different Apple framework, and
  requires a Widget Extension target which this project dropped 2026-09-10).
- Guest/email/Google users. This only works for Apple-signed-in users, since
  they're the only ones with a real Supabase Auth session today (`auth.uid()`
  is what every new table's RLS keys off). Unifying auth for other providers
  is tracked separately in `TODO.md` §3 and not part of this work.
- A separate on/off toggle for this specific notification type — it rides
  the existing `notificationsEnabled` switch.

## Why there's only one viable architecture

Apple's Sign-in-with-Apple-style authorization code for push registration
isn't the relevant constraint here (that was the delete-account spec, now
parked) — the actual constraint is simpler: **something has to run on a
schedule, server-side, independent of whether the app is open.** No amount
of client cleverness substitutes for a cron job plus a way to reach Apple's
push service. That fixes the shape: a stored device token + timezone per
user, a scheduled check, and a call to APNs.

## Apple Developer portal artifacts (already obtained this session)

- **APNs Auth Key**: Key ID `N7992N49CB`
- **Team ID**: `F4NF2ZRZS9` (confirmed via Membership page; note — the
  certificate currently installed on the dev Mac resolves to a *different*
  team, `9N7QP3D3Y9`, for reasons still not fully run to ground — see
  "Known open issue" below. The APNs Key itself was created under the
  correct team, `F4NF2ZRZS9`, which is what actually matters for signing
  APNs JWTs.)
- **Push Notifications capability**: added to the `BreathRelaxStretch`
  Xcode target; builds clean.

**Known open issue, not blocking:** the local signing certificate's team
(`9N7QP3D3Y9`) doesn't match the enrolled Program team (`F4NF2ZRZS9`).
Removing/re-adding the account in Xcode did not surface a second team,
which most likely means Apple's backend hasn't finished propagating the
very-recent enrollment into Xcode's account-linking system yet. Since
adding the Push Notifications capability itself succeeded with no error,
this isn't currently blocking implementation — flagged here so it isn't
forgotten, and worth re-checking (Xcode account refresh) before this
feature ships to a real device.

## Data model

One new table, two new columns on the existing `profiles` table. Both fold
into `supabase_schema.sql` alongside the existing four tables.

```sql
-- ───────────────────────── profiles (additions) ─────────────────────────
alter table profiles add column if not exists last_session_at timestamptz;

-- ───────────────────────── push_tokens ─────────────────────────
-- One row per signed-in device. Not publicly readable — only the service
-- role (used exclusively by Edge Functions) ever reads this table; RLS
-- still lets an owner manage their own row directly for register/unregister.

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
```

Why `timezone` as an IANA name and not a raw UTC offset: an offset goes
stale across DST twice a year; a name lets Postgres's
`at time zone` conversion stay correct automatically.

## Client changes

- **New capability**: Push Notifications (done).
- **New `AppDelegate`**: the app currently has no `UIApplicationDelegateAdaptor`
  (pure SwiftUI App lifecycle) — one is needed to receive
  `didRegisterForRemoteNotificationsWithDeviceToken` /
  `didFailToRegisterForRemoteNotificationsWithError`.
- **Registration trigger**: when `notificationsEnabled` is true AND
  `AuthManager.shared.isBackendAuthenticated` (Apple session exists), call
  `UIApplication.shared.registerForRemoteNotifications()`. Checked at app
  launch and whenever the toggle flips on in `ProfileSettingsTab`/
  `NotificationsPage`.
- **Token upload**: on successful registration, hex-encode the token and
  `POST`/upsert it to `push_tokens` along with `TimeZone.current.identifier`,
  best-effort (same fire-and-forget pattern as every other Supabase call in
  this codebase).
- **Token removal**: when `notificationsEnabled` flips off, call
  `UIApplication.shared.unregisterForRemoteNotifications()` and delete the
  `push_tokens` row.
- **`last_session_at`**: `SessionRecorder.record()` (the single funnel point
  for session completion) gains a best-effort call to upload the current
  profile snapshot — including `last_session_at = completedAt` — to
  `profiles`, guarded the same way (`SupabaseService.isConfigured &&
  AuthManager.shared.isBackendAuthenticated`). This is new — session
  completion doesn't currently touch Supabase at all; today's only
  `uploadProfile` call site is `LeaderboardView`, triggered by viewing the
  leaderboard, which isn't a reliable enough signal for this feature.
- **`RemoteProfile`**: gains `lastSessionAt: Date?` (`last_session_at`).
- **New DTO**: `RemotePushToken` (`device_token`, `timezone`) for the upsert.

## Server: `send-streak-warnings` Edge Function

One function, invoked on a schedule (not by the client). Responsibilities,
in order:

1. Query (via its own service-role Postgres connection) all rows in
   `push_tokens` joined to `profiles` where:
   - `profiles.streak >= 2` (protect meaningful streaks only — matches the
     existing `GamificationService.detectStreakBreak` threshold already
     used client-side for the freeze-token mechanic)
   - the local hour at `push_tokens.timezone` is 20 (8pm)
   - `profiles.last_session_at` is before the start of today in that same
     local timezone (i.e., no session yet today)
   - `push_tokens.last_warned_date` is null or not equal to today's local
     date for that timezone
2. For each match: build an ES256 JWT (`kid: N7992N49CB`, `iss: F4NF2ZRZS9`,
   signed with the APNs `.p8` key stored as a function secret), POST to
   `https://api.push.apple.com/3/device/{device_token}` (production) or
   `https://api.sandbox.push.apple.com/3/device/{device_token}` (debug
   builds — see "environment" note below) with a plain alert payload.
3. On success: stamp `last_warned_date` to today's local date for that row.
4. On a `410` (`Unregistered`) response from Apple: delete the stale
   `push_tokens` row instead of retrying it forever.
5. On any other failure: log and move to the next candidate — one user's
   failure never blocks the batch.

**Environment note:** a device's token is only valid against the matching
APNs environment (sandbox for Debug-signed builds, production for
TestFlight/App Store). Since this app has no server-side record of which
environment a given token belongs to yet, the function tries production
first and falls back to sandbox on a specific "BadDeviceToken" error — the
standard workaround until this app has TestFlight builds where environment
stops being ambiguous.

## Scheduling

`pg_cron` and `pg_net` are both available on the Supabase plan but not yet
enabled. `supabase_vault` is already enabled, and is where the service-role
key belongs — `cron.job` definitions are visible to anyone with sufficient
database privileges, so the key must never be inlined as a literal in the
scheduled SQL itself.

```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- One-time, run manually (not part of this file, since it's a secret):
-- select vault.create_secret('<service-role-key>', 'service_role_key');

select cron.schedule(
  'streak-warning-check',
  '*/15 * * * *', -- every 15 minutes
  $$
  select net.http_post(
    url := '<edge-function-url>/send-streak-warnings', -- filled in at deploy time, project-specific
    headers := jsonb_build_object(
      'Authorization',
      'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    )
  );
  $$
);
```

Every-15-minutes with the `last_warned_date` idempotency guard means a user
in any timezone gets checked within 15 minutes of their local 8pm, exactly
once.

## Error handling

- Device-token upload/removal failures: best-effort, logged, non-fatal —
  matches every other Supabase call site in this app.
- Stale tokens (410 from Apple): deleted from `push_tokens`, not retried.
- Cron/function failures: visible in Supabase logs; nothing user-facing,
  nothing to alert on immediately — a missed evening's warning is a minor
  miss, not a correctness bug.

## Security considerations

- `push_tokens` has no `select` policy — the client can write its own row
  but never read any row back (its own or anyone else's) through the normal
  REST API. Only the Edge Function's service-role connection can read it.
- The APNs `.p8` key content lives only as a Supabase Edge Function secret,
  never in the repo, never in the client binary.
- There is no client-facing Edge Function for the write path — see
  "Decision: `push_tokens` writes go through direct PostgREST" below — so
  the RLS policies above are the only enforcement point for reads/writes
  to `push_tokens`. The one Edge Function this feature does add
  (`send-streak-warnings`) is cron-triggered only and is never
  client-reachable at all.

## Testing plan

1. **Local build sanity**: confirm the app still builds clean with the new
   `AppDelegate` and capability (Simulator).
2. **Simulated push, no server**: once the client-side registration code
   exists, `xcrun simctl push booted <bundle-id> payload.json` to confirm
   the notification renders correctly client-side, without needing the real
   Edge Function/cron pipeline built yet.
3. **Real end-to-end test** (matches how Sign in with Apple was verified):
   sign in with Apple, manually set `last_session_at` far enough in the
   past and `streak >= 2` via a direct SQL update, temporarily narrow the
   cron's hour check (or just wait for actual local 8pm) on a **real
   device** — Simulator can't receive genuine remote APNs pushes — and
   confirm the notification arrives, then confirm `last_warned_date`
   stamped and a second cron tick doesn't double-send.

## Decision: `push_tokens` writes go through direct PostgREST, not a function

Resolved in favor of direct PostgREST upsert — confirmed against the
current codebase, which has no `supabase/functions/` directory at all yet;
every existing table (`profiles`, the leaderboard tables, etc.) is written
by the client the same way, straight through PostgREST under RLS. Adding a
function for this one write would be the first exception to that pattern,
and there's no requirement driving it: the RLS policies above already
express the entire access rule ("a user may only write their own row"),
which is exactly what RLS is for. A function only earns its place when
logic can't be expressed as an RLS predicate — the send-side path is that
case (it needs the APNs secret key and a cron trigger), the write-side path
isn't.

Concretely, this means:
- The client-side "Token upload" / "Token removal" steps in **Client
  changes** above are plain Supabase client calls
  (`.upsert(_:onConflict:)` / `.delete()`) against `push_tokens`, the same
  shape as every other `SupabaseService` write in this codebase — no new
  endpoint, no new request type.
- `send-streak-warnings` remains the only Edge Function this feature adds.
- The **Security considerations** note about verifying an inbound client
  JWT "if the client calls a function rather than hitting `push_tokens`
  directly via PostgREST" no longer applies — there is no such function,
  so that path is moot and RLS is the only enforcement point for the write
  side.
