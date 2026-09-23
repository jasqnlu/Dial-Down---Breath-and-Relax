# Investigation + fix: streaks not syncing across devices, plus a sign-in sync-status banner

Date: 2026-09-22
Status: **Fixed and merged into this branch.** Verified in the iOS Simulator.

## Symptom

> "the streaks on supabase don't actually save or any information. They only save on the same device however on different devices on the same account things don't load in."

## Root cause 1: no download path existed

Local `UserProfile` storage is device-only — `ModelConfiguration(..., cloudKitDatabase: .none)`
in `Breath__Relax___StretchApp.swift` (no CloudKit, deliberately, per its own comment: the
entitlement isn't set up yet). That makes the Supabase `profiles` row the *only* possible
cross-device channel for `streak`/`totalPoints`/`totalMinutes` — but it was wired **write-only**:

- `SessionRecorder.record()` uploads a `RemoteProfile` snapshot after every session
  (`SupabaseService.uploadProfile`). This path was always correct — the data genuinely does
  land in Supabase.
- `SupabaseService.fetchProfile(id:)` is the only function that reads a profile row back down,
  and its only caller, `RegistrationCoordinator.fetchLookup`, used it exclusively to check
  `firstName`/`lastName` for the name-entry step. `row.streak`/`row.totalPoints`/
  `row.totalMinutes`/`row.lastSessionAt` were fetched and silently discarded.
- On a second device, `RootView.ensureUserProfile()` creates a fresh local `UserProfile` at
  `streak: 0` whenever none exists locally — it never asked Supabase whether the account
  already had progress.

### Fix

Added `RootView.pullRemoteProfile()` in `Breath__Relax___StretchApp.swift`, triggered by
`.onChange(of: auth.isBackendAuthenticated)` and once more in `.onAppear` (covers a session
already restored at cold launch). It fetches the remote `profiles` row and merges
`streak`/`totalPoints`/`totalMinutes`/`lastSessionDate` into the local `UserProfile` by taking
the max/latest of each field — the same reconciliation policy `UserProfile.dedupe` already uses
for merging duplicate local rows, so a device that's behind catches up without a device that's
ahead (but hasn't uploaded yet) ever losing progress.

## Root cause 2: why the fix still looked broken

Testing happened in the iOS Simulator using Sign in with Apple. Inspecting both booted
simulators directly (their `UserDefaults` plists under
`~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/*/Library/Preferences/`)
showed one had `isSignedIn = true, provider = apple` but **no `auth.supabaseUserID` key at
all** — the exact in-between state that exists only when the Apple → Supabase token exchange
never completed. The unified log confirmed it:

```
Apple → Supabase token exchange failed: SupabaseError.httpError(400)
```

Checking `.../data/Library/Preferences/com.apple.appleaccount.plist` on that simulator showed
it empty — **no real Apple ID signed into the simulator's Settings app.** Without one, iOS
Simulator's "Sign in with Apple" falls back to a locally-fabricated credential that Apple never
actually signs, so Supabase's server-side verification against Apple's real JWKS correctly
rejects it with 400. Neither the old upload path nor the new download path had anything to do
with this — both are gated behind `isBackendAuthenticated`, which never became true.

This also explains an "unexplained" line in the prior investigation,
`docs/investigations/2026-09-19-apple-account-data-not-saved.md`: *"Two `POST
/auth/v1/token?grant_type=id_token` requests returned 400 ... unexplained."* Same cause.

**Fix (environment, not code):** sign into a real Apple ID under the Simulator's Settings app,
then sign out/in with Apple in the app again. Confirmed working after that.

## Follow-on: surfacing sign-in backend-sync status in the UI

Investigating root cause 2 exposed a real gap independent of the Simulator: when the Apple →
Supabase exchange fails on a **real device** (network hiccup, revoked token, etc.), the user has
no way to know. `AuthManager.handleAppleCredential` persists local sign-in immediately
(`persist(...)`), then runs the backend exchange in a detached `Task` whose only failure
handling was a `Logger.warning` — invisible to the user. The account silently degrades to
"locally signed in, not backend-authenticated": sync, leaderboard, and cross-device streak pull
all silently stop working.

Google and email/password don't have this gap — `handleGoogleSignIn`/`signIn`/`signUp` are
synchronous from the caller's perspective and only persist local sign-in *after* the backend
exchange succeeds, surfacing failures as an inline error in `AuthView` before letting the user
in. Only Apple's credential arrives from a system delegate callback with no synchronous caller
to report to, which is why it took the fire-and-forget shape it did.

### Design

**`AuthManager` (`Services/AuthManager.swift`):**
- `@Published private(set) var backendSyncFailed: Bool` — true when local Apple sign-in
  succeeded but the backend exchange didn't.
- `@Published var justReconnected: Bool` — transient pulse, set true right after a manual retry
  succeeds; the UI resets it back to false once it's shown the confirmation.
- `pendingAppleRetry: (identityToken: String, nonce: String?)?` — the failed exchange, kept in
  memory only (never persisted). Apple identity tokens are single-use with a ~10 minute TTL, so
  a retry attempted long after the original failure just fails again with the same error — there
  is intentionally no cross-launch retry; the user signs in with Apple again at that point,
  which was already the accepted UX here.
- `retryBackendConnection()` — resends the cached token via `retryBackendConnection()`.
- Both `backendSyncFailed` and `pendingAppleRetry` are cleared on sign-out
  (`endSupabaseSession()`), so a stale banner never survives into the next account on the same
  device.
- **Testability fix:** `handleAppleCredential`'s exchange previously called
  `SupabaseService.shared.signInWithApple(...)` directly, bypassing the `SupabaseAuthenticating`
  test seam that Google/email/password already used — this is why there was no
  `handleAppleCredential` test. Added `signInWithApple` to the `SupabaseAuthenticating` protocol
  and routed the call through `self.supabase`, and split the exchange into an `internal`
  `exchangeAppleToken(identityToken:nonce:)` so tests can drive the retry/state-machine directly
  (an `ASAuthorizationAppleIDCredential` has no public initializer, so `handleAppleCredential`
  itself still can't be unit tested — same constraint as before).

**UI — `Views/Auth/BackendSyncBanner.swift`:** a slim banner mounted once at
`RootView` via `.overlay(alignment: .top)`, so it's visible from any tab rather than tied to the
Profile/Account screen, and doesn't conflict with the floating tab bar (bottom-anchored).
- **Failure state:** warning icon, "Signed in, but sync isn't connected", a **Retry** button
  (shows a spinner while in flight), and a dismiss (×) that hides it for the rest of this
  occurrence of the failure — dismissing resets automatically if `backendSyncFailed` goes
  true again later (e.g. a fresh sign-in that also fails).
- **Success state:** green check, "Connected", auto-dismisses after ~2 seconds. Shown only after
  a manual Retry succeeds — the normal first-try sign-in path stays silent, unchanged from
  today.

### Explicitly out of scope

- **Not blocking sign-in** on the backend exchange succeeding — the user keeps using the app
  locally either way; the banner is informational + actionable, not a gate.
- **Not re-presenting Apple's native sign-in sheet from the banner.** Retry only resends the
  cached (still-valid) token. If it's expired, the retry fails again with a message pointing the
  user at signing in with Apple again — matches the pre-existing code comment's accepted design,
  and avoids the complexity of driving `ASAuthorizationController` from deep in the view
  hierarchy for comparatively little benefit.
- **Not changing Google's behavior.** It already handles this correctly (blocks entry, surfaces
  an inline error) and isn't part of this bug.

### Testing

- `AuthManagerTests.swift`: 7 new tests covering the state machine — failure sets
  `backendSyncFailed` without touching local sign-in state, a normal first-try success never
  pulses `justReconnected`, a successful retry clears the failure and pulses `justReconnected`,
  retrying with nothing pending is a no-op, a second failed retry keeps the failure state, and
  sign-out clears both the flag and the retryable token.
- Manual: reproduced the exact Simulator scenario from root cause 2 (no real Apple ID signed
  in), confirmed the banner appears; signed into a real Apple ID, tapped Retry, confirmed the
  "Connected" toast and that `pullRemoteProfile` then runs successfully.
- Full unit suite run clean except one pre-existing flake (`LeaderboardHandleTests
  .preferenceRoundTripsAndClears`, shared-`UserDefaults` test-isolation race documented
  elsewhere in the test suite — passes in isolation, unrelated to this change).

## Also surfaced, not fixed here

- **Email confirmation is enabled** on this Supabase project's Auth provider settings
  (`wmsutfittuxrvcwuywrk`), but `AuthManager.signUpWithPassword`'s existing comments assume it's
  disabled. A real email/password signup today gets a 200 response with no session, which the
  code can't decode as a `TokenGrant`, surfacing as a generic "Couldn't create your account"
  error. Left as-is per discussion — either flip "Confirm email" off in the dashboard (zero code
  changes needed), or build a proper pending-confirmation UI as a separate follow-up.
- One throwaway unconfirmed test user was created while reproducing the above:
  `07jasonlu2010+clauderepro*@gmail.com`. Harmless; can be deleted from Authentication → Users.
