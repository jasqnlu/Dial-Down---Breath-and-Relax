# Streak-About-To-Break Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the one push-notification type from the spec — a server-triggered
"your streak is about to break" alert sent around 8pm local time to any
Apple-signed-in user with `streak >= 2` who hasn't done a session yet today.

**Architecture:** Client registers for remote notifications and upserts its
APNs device token + IANA timezone to a new `push_tokens` table (direct
PostgREST, RLS-scoped, no Edge Function on the write side). Session
completion best-effort-uploads `last_session_at` onto the existing `profiles`
table. A `pg_cron` job fires every 15 minutes, calling one Edge Function
(`send-streak-warnings`) that asks Postgres (via a `security definer`
function that does the per-row IANA-timezone math) which tokens are due,
signs an APNs ES256 JWT, and posts the alert.

**Tech Stack:** SwiftUI / Swift 6 (client), Supabase Postgres + RLS + `pg_cron`
+ `pg_net` + `supabase_vault`, Supabase Edge Functions (Deno/TypeScript),
Web Crypto API (`ECDSA` / P-256) for APNs JWT signing — no external JWT
library needed.

**Spec:** `docs/superpowers/specs/2026-09-11-streak-notifications-design.md`
— read it alongside this plan; task descriptions below assume its rationale
(why RLS-only, why IANA timezone names, why prod-then-sandbox) rather than
re-deriving it.

## Global Constraints

- Every existing Supabase write in this codebase is best-effort and never
  throws to the UI (`try? await SupabaseService.shared....`) — match this
  for every new client call site; do not add error-surfacing UI.
- Gate every new push-registration/upload call behind
  `SupabaseService.isConfigured && AuthManager.shared.isBackendAuthenticated`
  — guests/local accounts have no Supabase Auth session and RLS rejects
  their writes anyway.
- `push_tokens` RLS: `auth.uid()::text = user_id` on insert/update/delete,
  **no select policy** — only the service role (Edge Function) ever reads
  rows back.
- Streak threshold for "meaningful streak": `>= 2` — matches
  `GamificationService.checkForBrokenStreak`'s existing threshold
  (`Breath - Relax & Stretch/Services/GamificationService.swift:76`).
- Local-hour trigger: hour `20` (8pm). Cron cadence: every 15 minutes
  (`*/15 * * * *`) — with the `last_warned_date` idempotency guard this
  checks every timezone within 15 minutes of its local 8pm, exactly once.
- APNs Key ID: `N7992N49CB`. Team ID (JWT `iss`): `F4NF2ZRZS9`.
- APNs endpoints: `https://api.push.apple.com/3/device/{token}` (production)
  tried first, falling back to
  `https://api.sandbox.push.apple.com/3/device/{token}` (sandbox) only on a
  `BadDeviceToken` response — this app has no server-side record yet of
  which environment a token belongs to.
- Column length caps (matches every other table in `supabase_schema.sql`):
  `push_tokens.user_id` ≤ 40, `device_token` ≤ 200, `timezone` ≤ 64.
- Follow the existing DTO split: request/response structs go in
  `SupabaseDTOs.swift`, never in `SupabaseService.swift` (keeps Swift 6 from
  inferring `@MainActor` isolation onto the actor's file — see the comment
  at the top of `SupabaseDTOs.swift`).
- This Xcode project uses `PBXFileSystemSynchronizedRootGroup`s — a new
  `.swift` file dropped into `Breath - Relax & Stretch/Services/` or
  `.../Tests/` is picked up automatically; no `project.pbxproj` edits needed.

---

## File Structure

| File | Change |
|---|---|
| `supabase_schema.sql` | Modify — add `profiles.last_session_at`, the `push_tokens` table + RLS, and a new `get_streak_warning_candidates()` SQL function |
| `Breath - Relax & Stretch/Services/SupabaseDTOs.swift` | Modify — add `RemotePushToken`, add `lastSessionAt` to `RemoteProfile` |
| `Breath - Relax & Stretch/Services/SupabaseService.swift` | Modify — add `registerPushToken(deviceToken:timezone:)`, `deletePushToken()` |
| `Breath - Relax & Stretch/Services/AppDelegate.swift` | Create — `UIApplicationDelegateAdaptor` target, receives the device token |
| `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift` | Modify — wire the `AppDelegate`, register for remote notifications at launch when eligible |
| `Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift` | Modify — register/unregister on the existing `notificationsEnabled` toggle |
| `Breath - Relax & Stretch/Views/Onboarding/NotificationsPage.swift` | Modify — register on first-run opt-in |
| `Breath - Relax & Stretch/Views/Profile/LeaderboardView.swift` | Modify — pass `lastSessionAt` into the `RemoteProfile` it already builds |
| `Breath - Relax & Stretch/Services/SessionRecorder.swift` | Modify — best-effort upload of `last_session_at` on session completion |
| `Breath - Relax & StretchTests/SupabaseDTOsTests.swift` | Create — encode/decode coverage for the new DTOs |
| `supabase/functions/send-streak-warnings/index.ts` | Create — the cron-triggered Edge Function |

---

### Task 1: Database schema — `push_tokens`, `profiles.last_session_at`, candidate query

**Files:**
- Modify: `supabase_schema.sql`

**Interfaces:**
- Produces: table `push_tokens(user_id, device_token, timezone, last_warned_date, updated_at)`; column `profiles.last_session_at timestamptz`; function `get_streak_warning_candidates() returns table(user_id text, device_token text, timezone text)` — Task 7's Edge Function calls this by name via `supabase.rpc('get_streak_warning_candidates')`.

- [ ] **Step 1: Append the schema to `supabase_schema.sql`**

Add this block at the end of the file (after the existing `profiles`
section):

```sql
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
```

- [ ] **Step 2: Apply the migration to the live project**

Use the Supabase MCP tool `mcp__supabase__apply_migration` with the SQL
block above (name it e.g. `streak_notifications_schema`) against this
project (ref `wmsutfittuxrvcwuywrk`, matching `SupabaseService.supabaseURL`).

- [ ] **Step 3: Verify against the live project**

Run (via `mcp__supabase__execute_sql`):

```sql
select column_name from information_schema.columns
where table_name = 'profiles' and column_name = 'last_session_at';

select table_name from information_schema.tables where table_name = 'push_tokens';

select routine_name from information_schema.routines
where routine_name = 'get_streak_warning_candidates';
```

Expected: each query returns exactly one row.

- [ ] **Step 4: Commit**

```bash
git add supabase_schema.sql
git commit -m "db: add push_tokens table, profiles.last_session_at, streak-warning candidate query"
```

---

### Task 2: DTOs — `RemotePushToken`, `RemoteProfile.lastSessionAt`

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SupabaseDTOs.swift`
- Test: `Breath - Relax & StretchTests/SupabaseDTOsTests.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `RemotePushToken(deviceToken: String, timezone: String)` — Codable,
  `CodingKeys` mapping to `device_token`/`timezone`; used by Task 3's
  `registerPushToken`. `RemoteProfile.lastSessionAt: Date?` (new field,
  `CodingKeys.lastSessionAt = "last_session_at"`) — used by Task 3/6.

- [ ] **Step 1: Write the failing tests**

Create `Breath - Relax & StretchTests/SupabaseDTOsTests.swift`:

```swift
import Foundation
import Testing
@testable import BreathRelaxStretch

struct SupabaseDTOsTests {

    @Test func remoteProfileEncodesLastSessionAtUnderSnakeCaseKey() throws {
        let date = Date(timeIntervalSince1970: 1_757_000_000) // fixed, so this test never flakes
        let profile = RemoteProfile(
            id: "abc-123", displayName: "Jason", totalPoints: 40,
            streak: 3, totalMinutes: 12, lastSessionAt: date
        )
        let data = try JSONEncoder().encode(profile)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["last_session_at"] != nil)
        #expect(json["lastSessionAt"] == nil)
    }

    @Test func remoteProfileDecodesNullLastSessionAt() throws {
        let json = """
        {"id":"abc-123","display_name":"Jason","total_points":40,"streak":3,"total_minutes":12,"last_session_at":null}
        """
        let profile = try JSONDecoder().decode(RemoteProfile.self, from: Data(json.utf8))
        #expect(profile.lastSessionAt == nil)
    }

    @Test func remotePushTokenEncodesUnderSnakeCaseKeys() throws {
        let token = RemotePushToken(deviceToken: "aa11bb22", timezone: "America/Los_Angeles")
        let data = try JSONEncoder().encode(token)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["device_token"] as? String == "aa11bb22")
        #expect(json["timezone"] as? String == "America/Los_Angeles")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"Breath - Relax & StretchTests/SupabaseDTOsTests"`
Expected: build failure — `RemotePushToken` doesn't exist yet, and
`RemoteProfile.init` doesn't take `lastSessionAt`.

- [ ] **Step 3: Implement the DTO changes**

Edit `SupabaseDTOs.swift` — replace the existing `RemoteProfile` struct with:

```swift
struct RemoteProfile: Codable, Sendable, Identifiable {
    let id: String              // stable identifier — AuthManager.backendID (anonymous UUID), never an email
    let displayName: String
    let totalPoints: Int
    let streak: Int
    let totalMinutes: Int
    /// Local wall-clock time of the most recent completed session, used
    /// server-side (via get_streak_warning_candidates) to tell whether a
    /// user has already practiced today in their own timezone.
    let lastSessionAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName  = "display_name"
        case totalPoints  = "total_points"
        case streak
        case totalMinutes = "total_minutes"
        case lastSessionAt = "last_session_at"
    }
}

/// Upsert body for `push_tokens`. `user_id` is never included here — it's
/// implied by the authenticated request (RLS's `auth.uid()`), matching how
/// every other insert in this codebase omits the owner column from its body.
struct RemotePushToken: Codable, Sendable {
    let deviceToken: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case timezone
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the same `xcodebuild test` command as Step 2.
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SupabaseDTOs.swift" "Breath - Relax & StretchTests/SupabaseDTOsTests.swift"
git commit -m "feat: add RemotePushToken DTO, RemoteProfile.lastSessionAt"
```

---

### Task 3: `SupabaseService` push-token methods + wire `lastSessionAt` into the existing upload

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SupabaseService.swift`
- Modify: `Breath - Relax & Stretch/Views/Profile/LeaderboardView.swift`

**Interfaces:**
- Consumes: `RemotePushToken` (Task 2), `AuthManager.shared.backendID` (existing).
- Produces: `SupabaseService.registerPushToken(deviceToken: String, timezone: String) async throws`,
  `SupabaseService.deletePushToken() async throws` — consumed by Task 5.

This task's network calls follow the exact same actor-method shape as
`uploadProfile`/`deleteProfile` above them, which this codebase has never
unit-tested directly (no `URLProtocol` stub harness exists here — see
`SupabaseServiceTests.swift`, which only tests the pure `isValidAPIHost`
helper). Consistent with that, verification here is build-clean + the
manual end-to-end pass in Task 9, not a unit test.

- [ ] **Step 1: Add the two methods to `SupabaseService.swift`**

Insert after `deleteProfile(id:)` (which precedes `fetchLeaderboard`):

```swift
    // MARK: - Push tokens (streak-about-to-break notifications)

    /// Upserts this device's APNs token + IANA timezone. Requires a Supabase
    /// Auth session (`AuthManager.isBackendAuthenticated`) — RLS rejects the
    /// write otherwise, which is fine: this call is always best-effort
    /// (`try?`) at every call site, exactly like `uploadProfile`.
    ///
    /// Expected Supabase table `push_tokens` — see supabase_schema.sql.
    func registerPushToken(deviceToken: String, timezone: String) async throws {
        let payload = RemotePushToken(deviceToken: deviceToken, timezone: timezone)
        let data = try await MainActor.run { try JSONEncoder().encode(payload) }
        try await post(path: "/rest/v1/push_tokens", body: data, upsert: true)
    }

    /// Deletes this user's push_tokens row (e.g. the notifications toggle
    /// was switched off). Deletes by the currently authenticated user's own
    /// row — the RLS delete policy only ever lets a session remove
    /// `auth.uid()`'s own row, so no id needs to be passed.
    func deletePushToken() async throws {
        guard let userID = supabaseUserID else { return }
        let encoded = userID.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? ""
        try await delete(path: "/rest/v1/push_tokens?user_id=eq.\(encoded)")
    }
```

- [ ] **Step 2: Wire `lastSessionAt` into `LeaderboardView`'s existing `uploadProfile` call**

In `LeaderboardView.swift`, update the `RemoteProfile(...)` construction
inside `load()`:

```swift
            let remote = RemoteProfile(
                id: auth.backendID,
                displayName: local.displayName,
                totalPoints: local.totalPoints,
                streak: local.streak,
                totalMinutes: local.totalMinutes,
                lastSessionAt: local.lastSessionDate
            )
```

- [ ] **Step 3: Build sanity**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SupabaseService.swift" "Breath - Relax & Stretch/Views/Profile/LeaderboardView.swift"
git commit -m "feat: add push-token register/delete, thread lastSessionAt through uploadProfile"
```

---

### Task 4: `AppDelegate` + launch-time registration

**Files:**
- Create: `Breath - Relax & Stretch/Services/AppDelegate.swift`
- Modify: `Breath - Relax & Stretch/Breath__Relax___StretchApp.swift`

**Interfaces:**
- Consumes: `SupabaseService.shared.registerPushToken(deviceToken:timezone:)` (Task 3),
  `AuthManager.shared.isBackendAuthenticated` (existing), `notificationsEnabled`
  (`@AppStorage`, existing key, read here via `UserDefaults.standard.bool`).
- Produces: `AppDelegate` class (installed via `@UIApplicationDelegateAdaptor`);
  a `shouldRegisterForRemotePush()` free function Task 5 also calls before
  flipping the toggle on.

This app currently has no `UIApplicationDelegateAdaptor` (pure SwiftUI
lifecycle) — this task adds the minimum one needed to receive the device
token callback. Like Task 3, the OS callback itself isn't unit-testable in
this codebase's existing style; it's verified via build + the `simctl push`
step in Task 9.

- [ ] **Step 1: Create `AppDelegate.swift`**

```swift
import UIKit
import os

/// The app is pure-SwiftUI-lifecycle everywhere else; this exists solely to
/// receive the two UIApplicationDelegate callbacks SwiftUI's App protocol
/// doesn't expose: the APNs device token (or the failure to get one).
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            guard SupabaseService.isConfigured, AuthManager.shared.isBackendAuthenticated else { return }
            try? await SupabaseService.shared.registerPushToken(
                deviceToken: hex,
                timezone: TimeZone.current.identifier
            )
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Best-effort feature — matches every other Supabase call site in
        // this app: log and move on, nothing user-facing.
        Logger(subsystem: "com.jasonlu.breath", category: "push").warning("APNs registration failed: \(error)")
    }
}

/// Shared eligibility check — the app only ever calls
/// `UIApplication.shared.registerForRemoteNotifications()` when both of
/// these hold. Called from three places: app launch (below), the
/// Reminders toggle (ProfileSettingsTab), and first-run opt-in
/// (NotificationsPage) — kept as one function so the rule can't drift
/// between them.
@MainActor
func shouldRegisterForRemotePush() -> Bool {
    UserDefaults.standard.bool(forKey: "notificationsEnabled")
        && AuthManager.shared.isBackendAuthenticated
}
```

- [ ] **Step 2: Wire the delegate + launch-time check into the App struct**

In `Breath__Relax___StretchApp.swift`, add the adaptor property (with the
other `@StateObject`s) and a registration call in the existing `.task`
that already runs `syncRemoteCatalog()`:

```swift
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
```

Then change:

```swift
                    .task { await syncRemoteCatalog() }
```

to:

```swift
                    .task {
                        await syncRemoteCatalog()
                        if shouldRegisterForRemotePush() {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
```

- [ ] **Step 3: Build sanity**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Services/AppDelegate.swift" "Breath - Relax & Stretch/Breath__Relax___StretchApp.swift"
git commit -m "feat: add AppDelegate for APNs registration, register at launch when eligible"
```

---

### Task 5: Toggle wiring — register/unregister from Settings and onboarding

**Files:**
- Modify: `Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift`
- Modify: `Breath - Relax & Stretch/Views/Onboarding/NotificationsPage.swift`

**Interfaces:**
- Consumes: `shouldRegisterForRemotePush()`, `AppDelegate` (Task 4);
  `SupabaseService.shared.deletePushToken()` (Task 3).

- [ ] **Step 1: `ProfileSettingsTab` — register/unregister on toggle**

In the existing `.onChange(of: notificationsEnabled)` block (around line 127),
add the remote-push calls alongside the existing local-notification ones:

```swift
                .onChange(of: notificationsEnabled) { _, enabled in
                    Task {
                        if enabled {
                            let granted = await NotificationService.shared.requestPermission()
                            if granted {
                                reschedule(weekdays: selectedWeekdays)
                                if shouldRegisterForRemotePush() {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                            } else {
                                notificationsEnabled = false
                            }
                        } else {
                            NotificationService.shared.cancelReminders()
                            UIApplication.shared.unregisterForRemoteNotifications()
                            if SupabaseService.isConfigured {
                                try? await SupabaseService.shared.deletePushToken()
                            }
                        }
                    }
                }
```

`ProfileSettingsTab.swift` currently has no `import UIKit` — add it at the
top of the file alongside the existing `import SwiftUI` for
`UIApplication.shared` to resolve.

- [ ] **Step 2: `NotificationsPage` — register on first-run opt-in**

In `requestNotificationsAndComplete()`, extend the `granted` branch:

```swift
    private func requestNotificationsAndComplete() {
        isRequesting = true
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                // Schedule Mon–Fri at 8 am (matches ProfileSettingsTab defaults)
                NotificationService.shared.scheduleReminders(
                    hour: 8, weekdays: [2, 3, 4, 5, 6])
                if shouldRegisterForRemotePush() {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            await MainActor.run {
                // Keep the persisted flag in sync with what actually happened —
                // otherwise a denial here leaves notificationsEnabled at its
                // default true with nothing actually scheduled, and
                // ProfileSettingsTab's Reminders section would show as "on"
                // with no way to notice it's inert.
                notificationsEnabled = granted
                isRequesting = false
                onComplete()
            }
        }
    }
```

(`NotificationsPage.swift` already `import`s `UserNotifications`; add
`import UIKit` for `UIApplication.shared`.)

Note: at onboarding time a brand-new Apple sign-in may not have
`isBackendAuthenticated` true yet depending on where this page sits in the
onboarding flow — `shouldRegisterForRemotePush()` simply returns false in
that case and nothing registers, which is correct (there's no session yet
to attach a token to); the Task 4 launch-time check catches it on the next
cold start once signed in.

- [ ] **Step 3: Build sanity**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Views/Profile/ProfileSettingsTab.swift" "Breath - Relax & Stretch/Views/Onboarding/NotificationsPage.swift"
git commit -m "feat: register/unregister remote push from the notifications toggle and onboarding"
```

---

### Task 6: Upload `last_session_at` on session completion

**Files:**
- Modify: `Breath - Relax & Stretch/Services/SessionRecorder.swift`

**Interfaces:**
- Consumes: `SupabaseService.shared.uploadProfile(_:)` (existing), `RemoteProfile`
  (Task 2), `AuthManager.shared.{backendID,isBackendAuthenticated}` (existing).

This is the first Supabase call site inside `SessionRecorder` — today
`uploadProfile` is only ever called from viewing the leaderboard
(`LeaderboardView`), which the spec calls out as "not a reliable enough
signal for this feature." `record()` is `@MainActor` but synchronous;
follow its own existing pattern of firing a detached-looking `Task { }` for
side effects (see the HealthKit block a few lines below) rather than making
`record()` itself `async`, which would ripple `await` onto every call site.

- [ ] **Step 1: Add the upload after the existing HealthKit/Calendar side effects**

In `SessionRecorder.record(_:modelContext:calendarSyncEnabled:)`, capture
the scalar profile fields *before* the `Task` (matching `LeaderboardView`'s
`local.displayName` pattern — a SwiftData `@Model` shouldn't be captured
directly across an actor-hopping closure), then add the upload. Insert
right after the existing HealthKit `Task { ... }` block and before the
`// Calendar` comment:

```swift
        // Community — best-effort upload of last_session_at so the
        // streak-warning server job knows this user already practiced
        // today. Snapshot scalar fields now; `profile` is a SwiftData
        // @Model and shouldn't be captured into the Task below.
        if let profile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
            let snapshot = RemoteProfile(
                id: AuthManager.shared.backendID,
                displayName: profile.displayName,
                totalPoints: profile.totalPoints,
                streak: profile.streak,
                totalMinutes: profile.totalMinutes,
                lastSessionAt: input.completedAt
            )
            Task {
                guard SupabaseService.isConfigured, AuthManager.shared.isBackendAuthenticated else { return }
                try? await SupabaseService.shared.uploadProfile(snapshot)
            }
        }

```

(The re-fetch here is deliberate, not redundant with the `profile` fetched
earlier in the same function: that earlier `if let profile = ...` binding
is scoped to its own `if` block above and already out of scope by this
point in the function.)

- [ ] **Step 2: Build sanity**

Run: `xcodebuild build -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run the existing test suite to confirm no regression**

Run: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme "Breath - Relax & Stretch" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: all tests that passed before this task still pass (this app's
`CuratedContentIntegrityTests` and the UITest-runner suite have known
pre-existing failures unrelated to this change — see
`docs/superpowers/...` history / project memory; don't chase those).

- [ ] **Step 4: Commit**

```bash
git add "Breath - Relax & Stretch/Services/SessionRecorder.swift"
git commit -m "feat: upload last_session_at to Supabase on session completion"
```

---

### Task 7: Edge Function `send-streak-warnings`

**Files:**
- Create: `supabase/functions/send-streak-warnings/index.ts`

**Interfaces:**
- Consumes: RPC `get_streak_warning_candidates()` (Task 1); env vars
  `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (auto-injected into every
  Supabase Edge Function — no secret to add); function secret
  `APNS_AUTH_KEY_P8` (the `.p8` file's raw text contents, added manually in
  Step 3 below — never committed).
- Produces: nothing consumed elsewhere in this repo — this is cron-invoked
  only (Task 8 wires the trigger).

- [ ] **Step 1: Write `supabase/functions/send-streak-warnings/index.ts`**

```typescript
// supabase/functions/send-streak-warnings/index.ts
//
// Cron-triggered only (see supabase_schema.sql's cron.schedule call) —
// never reachable from the client. Every 15 minutes: ask Postgres which
// (user, device) pairs are due a streak-about-to-break push right now in
// their own local time (get_streak_warning_candidates does the IANA-
// timezone math), sign one APNs JWT, and POST an alert to each.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const APNS_KEY_ID = "N7992N49CB";
const APNS_TEAM_ID = "F4NF2ZRZS9";

interface Candidate {
  user_id: string;
  device_token: string;
  timezone: string;
}

// ── APNs auth JWT (ES256) ────────────────────────────────────────────────
// Built with the Web Crypto API rather than a JWT library — Deno's
// crypto.subtle already speaks ECDSA/P-256, and WebCrypto's ECDSA signature
// output (raw r||s, 64 bytes for P-256) is exactly the format a JOSE ES256
// signature needs, so no DER-to-JOSE conversion step is required.
function base64url(bytes: ArrayBuffer | Uint8Array): string {
  const buf = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let str = "";
  for (const b of buf) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importAPNsPrivateKey(pem: string): Promise<CryptoKey> {
  const stripped = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(stripped), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

async function buildAPNsJWT(privateKey: CryptoKey): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const payload = { iss: APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) };
  const signingInput = `${base64url(new TextEncoder().encode(JSON.stringify(header)))}.` +
    `${base64url(new TextEncoder().encode(JSON.stringify(payload)))}`;
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64url(signature)}`;
}

// ── APNs delivery ────────────────────────────────────────────────────────

type SendResult = "sent" | "stale" | "failed";

async function sendOnePush(
  candidate: Candidate,
  jwt: string,
): Promise<SendResult> {
  const payload = JSON.stringify({
    aps: {
      alert: {
        title: "Don't lose your streak!",
        body: "You haven't practiced today — a quick session keeps your streak alive.",
      },
      sound: "default",
    },
  });

  const post = (host: string) =>
    fetch(`https://${host}/3/device/${candidate.device_token}`, {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": "com.jasonlu.Dial--Down--Breath--Stretch", // must match PRODUCT_BUNDLE_IDENTIFIER
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      body: payload,
    });

  // Production first — see the spec's "Environment note": this app has no
  // stored record yet of which APNs environment a given token belongs to.
  let response = await post("api.push.apple.com");
  if (response.status === 400) {
    const body = await response.json().catch(() => ({}));
    if (body.reason === "BadDeviceToken") {
      response = await post("api.sandbox.push.apple.com");
    }
  }

  if (response.status === 200) return "sent";
  if (response.status === 410) return "stale"; // Unregistered — delete, don't retry
  return "failed";
}

// ── Entry point ──────────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  const apnsKeyPEM = Deno.env.get("APNS_AUTH_KEY_P8");
  if (!apnsKeyPEM) {
    return new Response("APNS_AUTH_KEY_P8 not configured", { status: 500 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: candidates, error } = await supabase.rpc(
    "get_streak_warning_candidates",
  );
  if (error) {
    console.error("get_streak_warning_candidates failed:", error);
    return new Response("query failed", { status: 500 });
  }
  if (!candidates || candidates.length === 0) {
    return new Response("no candidates", { status: 200 });
  }

  const privateKey = await importAPNsPrivateKey(apnsKeyPEM);
  const jwt = await buildAPNsJWT(privateKey);

  let sent = 0, stale = 0, failed = 0;
  for (const candidate of candidates as Candidate[]) {
    // One user's failure never blocks the batch — matches the spec's error
    // handling section.
    try {
      const result = await sendOnePush(candidate, jwt);
      if (result === "sent") {
        sent++;
        const localDate = new Date(
          new Date().toLocaleString("en-US", { timeZone: candidate.timezone }),
        ).toISOString().slice(0, 10);
        await supabase
          .from("push_tokens")
          .update({ last_warned_date: localDate })
          .eq("user_id", candidate.user_id);
      } else if (result === "stale") {
        stale++;
        await supabase.from("push_tokens").delete().eq("user_id", candidate.user_id);
      } else {
        failed++;
      }
    } catch (err) {
      failed++;
      console.error(`push failed for ${candidate.user_id}:`, err);
    }
  }

  return new Response(
    JSON.stringify({ candidates: candidates.length, sent, stale, failed }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
});
```

- [ ] **Step 2: Deploy the function**

Use the Supabase MCP tool `mcp__supabase__deploy_edge_function` with
`name: "send-streak-warnings"` and the file content above.

- [ ] **Step 3: Add the APNs key as a function secret (manual, one-time)**

This is a real secret — never paste its contents into a file in this repo.
Tell the user to run, with the actual `.p8` file downloaded from the Apple
Developer portal (Key ID `N7992N49CB`):

```bash
supabase secrets set APNS_AUTH_KEY_P8="$(cat /path/to/AuthKey_N7992N49CB.p8)" --project-ref wmsutfittuxrvcwuywrk
```

- [ ] **Step 4: Smoke-test the deployed function**

Run (via `mcp__supabase__execute_sql` or the Dashboard's function invoke UI)
a manual invocation and confirm it returns `{"candidates":0,...}` cleanly
before any real `push_tokens` rows exist — this proves the JWT-signing and
RPC-calling code paths don't throw, ahead of Task 9's full end-to-end pass.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/send-streak-warnings/index.ts
git commit -m "feat: add send-streak-warnings Edge Function"
```

---

### Task 8: `pg_cron` scheduling

**Files:**
- Modify: `supabase_schema.sql`

**Interfaces:**
- Consumes: the deployed `send-streak-warnings` function URL (Task 7).

- [ ] **Step 1: Append the scheduling block to `supabase_schema.sql`**

```sql
-- ───────────────────────── streak-warning cron ─────────────────────────
-- pg_cron/pg_net are available on this plan but not enabled by default.
-- supabase_vault is already enabled — the service-role key must live there,
-- never inlined as a literal in this file, since cron.job definitions are
-- visible to anyone with sufficient database privileges.
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- One-time, run manually via the Dashboard SQL editor (not part of this
-- file, since it's a secret):
--   select vault.create_secret('<service-role-key>', 'service_role_key');

select cron.schedule(
  'streak-warning-check',
  '*/15 * * * *', -- every 15 minutes
  $$
  select net.http_post(
    url := 'https://wmsutfittuxrvcwuywrk.supabase.co/functions/v1/send-streak-warnings',
    headers := jsonb_build_object(
      'Authorization',
      'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    )
  );
  $$
);
```

- [ ] **Step 2: Apply via Supabase MCP**

Use `mcp__supabase__apply_migration` for the `create extension` /
`cron.schedule` block above. The `vault.create_secret` line is commented
out deliberately — tell the user to run it themselves once, pasting their
actual service-role key (Dashboard → Settings → API → `service_role` —
never the `anon`/publishable key already in `SupabaseService.swift`) into
the Dashboard SQL editor directly, since that value must never pass through
this conversation or land in a file.

- [ ] **Step 3: Verify the job registered**

Run (via `mcp__supabase__execute_sql`):

```sql
select jobname, schedule, active from cron.job where jobname = 'streak-warning-check';
```

Expected: one row, `active = true`.

- [ ] **Step 4: Commit**

```bash
git add supabase_schema.sql
git commit -m "db: schedule send-streak-warnings via pg_cron every 15 minutes"
```

---

### Task 9: End-to-end verification

**Files:** none (verification only).

- [ ] **Step 1: Simulated push, no server**

With Tasks 4–5 built, run the app in Simulator, sign in with Apple, enable
notifications. Then:

```bash
xcrun simctl push booted com.jasonlu.Dial--Down--Breath--Stretch - <<'EOF'
{"aps":{"alert":{"title":"Don't lose your streak!","body":"Test push"},"sound":"default"}}
EOF
```

Expected: the notification banner renders in Simulator. This confirms the
client-side plumbing (permission → payload rendering) independent of the
real APNs/cron pipeline, per the spec's testing plan.

- [ ] **Step 2: Confirm `push_tokens` populates on a real device**

Simulator can't receive genuine remote APNs pushes or register a real
device token, so device-token upload can only be confirmed on a real
device: build to a real device, sign in with Apple, enable notifications,
then (via `mcp__supabase__execute_sql`):

```sql
select user_id, timezone, last_warned_date from push_tokens;
```

Expected: one row for the signed-in user, `timezone` matching the device's
`TimeZone.current.identifier`.

- [ ] **Step 3: Force a due candidate and confirm delivery**

Via `mcp__supabase__execute_sql`, set up a user who should be warned right
now:

```sql
update profiles set streak = 5, last_session_at = now() - interval '2 days'
where id = '<the signed-in user's auth.uid()>';
```

Manually invoke the deployed function (Dashboard → Edge Functions →
`send-streak-warnings` → Invoke, or `mcp__supabase__execute_sql` calling
`select net.http_post(...)` the same way the cron job does) and confirm:
- The push arrives on the real device.
- `push_tokens.last_warned_date` stamps to today's date afterward.
- Invoking it a second time does **not** send a second push (the
  `last_warned_date` guard in `get_streak_warning_candidates` excludes the
  row).

- [ ] **Step 4: Confirm the toggle-off path removes the token**

In the app, turn the Reminders toggle off. Then:

```sql
select count(*) from push_tokens where user_id = '<the signed-in user's auth.uid()>';
```

Expected: `0`.

---

## Self-Review Notes

- **Spec coverage:** every section of the design doc maps to a task —
  Data model → Task 1, Client changes → Tasks 2–6, Server Edge Function →
  Task 7, Scheduling → Task 8, Testing plan → Task 9. The one open question
  the spec left (direct PostgREST vs. a function for the write path) was
  already resolved in the spec itself before this plan was written — Task 3
  implements that resolution directly (no Edge Function on the write side).
- **Type consistency check:** `RemoteProfile.lastSessionAt` (Task 2) is used
  with that exact name and `Date?` type in both call sites that construct it
  (Task 3's `LeaderboardView` edit, Task 6's `SessionRecorder` snapshot).
  `shouldRegisterForRemotePush()` (Task 4) is called with the same name and
  no arguments from both Task 4's own launch-time site and both of Task 5's
  toggle sites. `get_streak_warning_candidates()` (Task 1) returns exactly
  the three columns (`user_id`, `device_token`, `timezone`) the `Candidate`
  interface in Task 7 destructures.
- **No placeholders:** every step above contains complete, runnable code —
  there is no "add error handling" or "similar to Task N" step in this plan.
