# Design: Supabase Auth wiring + Flexibility Check-Ins

Date: 2026-07-06 · Owner: Fable 5 (autonomous session; TODO.md items assigned to Fable)
Status: implemented in the same session — the TODO entries served as the approved requirements.

---

## Part 1 — Wire Supabase Auth end-to-end

### Problem

`SupabaseService.signInWithApple(identityToken:)` exists but is never called. Every
request runs on the anon key, so all write policies are anon-writable (leaderboard
spoofable, public routines editable by anyone). The access token, when set, lives
in memory only and expires after ~1 h with no refresh.

### Approach chosen

Keep the app's guest-first local auth exactly as is; layer a *backend session*
on top that exists only for Sign in with Apple users. Alternatives considered:

1. **Adopt supabase-swift SDK** — rejected: the codebase deliberately has zero
   SPM dependencies for auth (see GoogleAuthService's hand-rolled PKCE) and the
   REST surface used is tiny.
2. **Move all auth (email/password) to Supabase Auth** — rejected: local email
   accounts are a deliberate offline-first choice; migrating them is a product
   decision Jason hasn't made.
3. **Chosen: session layer for Apple sign-in only** — smallest change that makes
   `auth.uid()`-based RLS possible; guests keep read access, lose nothing they
   have today except spoofable writes (which is the point).

### Components

- **`SupabaseSession`** (new file `Services/SupabaseSession.swift`) — plain
  `Codable` + `Sendable` struct: `accessToken`, `refreshToken`, `userID`,
  `expiresAt`. Pure helper `needsRefresh(at:)` (true within 120 s of expiry) so
  the refresh policy is unit-testable without networking.
- **`SupabaseService`** — owns the session lifecycle:
  - persists the session JSON in the keychain via the existing `KeychainStore`
    seam (`SecItemKeychainStore(service: "com.breathapp.supabase")`), loaded
    lazily once per process;
  - `signInWithApple(identityToken:nonce:)` exchanges the Apple identity token
    at `/auth/v1/token?grant_type=id_token`, decodes the full grant (access +
    refresh token, expiry, user id), stores + persists it, returns the Supabase
    user id;
  - `refreshSession()` at `/auth/v1/token?grant_type=refresh_token`, run
    proactively from `currentAccessToken()` before any authorized request; a
    4xx from the refresh endpoint clears the session (revoked server-side);
  - auth endpoints use a bare request (anon Authorization) so refresh can never
    recurse; data endpoints attach the session token when present, anon key
    otherwise;
  - `signOut()` best-effort revokes at `/auth/v1/logout` then clears keychain +
    memory;
  - the dead `setAccessToken(_:)` API is deleted (replaced by the session).
- **`AuthManager`** —
  - `prepareAppleSignInRequest(_:)` sets scopes **and a SHA-256 nonce** (replay
    protection, raw nonce kept for the exchange);
  - `handleAppleCredential` extracts `identityToken`, fires a background task to
    run the Supabase exchange when `SupabaseService.isConfigured`; on success
    stores the Supabase user id in UserDefaults (`auth.supabaseUserID` — the id
    is not a secret; the tokens are, and they live in the keychain);
  - new `backendID: String` — Supabase user id when present, else the existing
    per-install anonymous UUID. This is what community features key rows on;
  - `signOut()` / `deleteAccount()` also clear the Supabase session (delete
    the leaderboard row first, while the token still authorizes it).
- **Call sites** — `LeaderboardView`, `BorrowRoutineView`, `RoutineBuilderView`
  switch `auth.anonymousID` → `auth.backendID`. The local SwiftData
  `UserProfile(profileID:)` keeps `anonymousID` (device identity, never uploaded).
- **`supabase_schema.sql`** — drops the anon-writable policies and recreates
  them as `auth.uid()`-scoped: routines insert/update/delete require
  `author_id = auth.uid()::text`; sessions insert requires
  `user_id = auth.uid()::text`; profiles insert/update/delete require
  `id = auth.uid()::text`. Public selects unchanged. `drop policy if exists`
  guards make the file safe to re-run on the existing project.

### Consequences / accepted trade-offs

- Guests and email/Google users can **read** community data but their uploads
  now 401/403 (all upload calls were already best-effort `try?`).
  `LeaderboardView` states this instead of failing silently.
- Rows uploaded under the old anonymous UUID before this change become
  unwritable/undeletable (no token can claim them). Acceptable: community
  features haven't launched publicly — that's what this task unblocks.
- If the token exchange fails (offline at sign-in), there is no stored Apple
  identity token to retry with (they're single-use, ~10 min TTL); the user can
  sign in with Apple again. Documented in code.
- Manual setup (added to TODO ⚙️ section): enable the Apple provider in
  Supabase Dashboard → Authentication → Providers, with the app's bundle ID as
  client ID, and re-run `supabase_schema.sql`.

### Testing

- `SupabaseSessionTests` — codable round-trip, `needsRefresh` boundaries.
- `AuthManagerTests` additions — `backendID` falls back to `anonymousID`,
  prefers the stored Supabase user id, and is cleared by `signOut`/`deleteAccount`.
- Networked paths (token exchange/refresh) are thin JSON mappings over the
  existing `post()` helper; exercised manually against the live project.

---

## Part 2 — Flexibility Check-Ins

### Problem

Bend's periodic "how far can you reach?" self-test is a retention
differentiator: it makes invisible progress visible. We have nothing measuring
flexibility itself — only minutes/streaks/points.

### Approach chosen

Ordinal self-assessment (no camera/ML, no free-form numbers). Alternatives:

1. **Numeric entry (cm past toes, degrees)** — rejected: nobody has a
   goniometer; junk data, intimidating UX.
2. **Camera/vision measurement** — rejected: big scope, privacy surface,
   accuracy theater.
3. **Chosen: 5-level ordinal scale per standard test** — matches how Bend and
   physio intake forms actually do it; honest, fast (< 1 min for all four),
   charts beautifully as a step line.

### Components

- **`FlexibilityTest`** (new `Models/FlexibilityCheckIn.swift`) — `enum … :
  String, CaseIterable, Identifiable, Codable`. Four standard tests, defined in
  code (catalog, not user data):
  - `toeTouch` — Toe Touch (hamstrings & lower back)
  - `shoulderReach` — Behind-Back Shoulder Reach, a.k.a. Apley scratch (shoulders)
  - `neckRotation` — Neck Rotation (neck)
  - `butterfly` — Butterfly Knees (hips & groin)
  Each exposes `name`, `targetArea`, `icon` (SF Symbol), `instructions`
  ([String], how to perform safely), and `levels` ([String], 5 entries worst →
  best, e.g. fingertips-to-knees … palms flat on floor).
- **`FlexibilityCheckIn`** (`@Model`, same file) — `uuid`, `date`,
  `testID: String` (raw value; String not enum keeps the schema
  CloudKit-simple like the rest of the models), `level: Int` (0–4). Inline
  defaults on every property per the project's CloudKit-compatibility rule.
  Registered in the app `Schema`. One row per test per check-in session.
- **`FlexibilityStats`** (same file) — pure functions over `[FlexibilityCheckIn]`:
  `latest(for:)`, `delta(for:)` (latest minus first level), `isDue(now:)`
  (no check-in in 14 days). Unit-testable without SwiftData.
- **`FlexibilityCheckInView`** (new `Views/Profile/FlexibilityCheckInView.swift`)
  — sheet flow, one page per test: icon, instructions, tappable level list,
  Skip / Save-and-next. Saves each answered test as a `FlexibilityCheckIn` on
  completion of the flow (not per page, so backing out saves nothing).
- **`flexibilitySection` in `ProgressChartsView`** — new card between All Time
  and Streak Calendar: per-test latest level + delta arrow, a Swift Charts
  step `LineMark` (level 0–4 vs date, one series per test with ≥ 2 data
  points), a "Check In" button, and a "time for a check-in" nudge when
  `isDue` (14-day cadence).

### Consequences / trade-offs

- No gamification points for v1 — keeps `GamificationService`/streak math
  untouched; can be added later as its own decision.
- Self-reported ordinal data can't regress smoothly (people round up); accepted
  — the goal is trend visibility, not clinical measurement.
- Catalog lives in code: adding a test is a code change, but there's no schema
  risk and no localization-in-database problem.

### Testing

`FlexibilityCheckInTests` — catalog invariants (4 tests, 5 levels each,
non-empty instructions), `FlexibilityStats.latest/delta/isDue` math, and a
SwiftData in-memory round-trip of the model (mirrors `SessionRecorderTests`
setup).
