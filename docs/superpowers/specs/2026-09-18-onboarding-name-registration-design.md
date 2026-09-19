# Onboarding showcase, name capture, and Supabase-backed registration

Date: 2026-09-18
Status: Approved design, pending implementation plan

## Goals

1. A fresh install sees a feature showcase (Body Map screenshots, exercise
   list) in onboarding, then lands on the sign-up / sign-in screen.
2. Every sign-in path (Apple, Google, email) collects first and last name.
3. An account with no registered profile in Supabase goes through the name step
   and the coach-mark tour again, even on a device that already onboarded.
4. A returning registered account skips both, and its name is restored from
   the server.

## Current state (from code)

- `Breath__Relax___StretchApp.swift`: `OnboardingGate { RootView() }`.
  `OnboardingGate` shows `OnboardingView` until the device-level
  `@AppStorage("hasCompletedOnboarding")` is true. `RootView` then routes
  `AuthView` -> `AppLockView` -> `HomeView` on `auth.isSignedIn` /
  `auth.needsUnlock`.
- `OnboardingGate` auto-starts the coach-mark tour once, gated by the global
  `hasSeenAppGuide` flag.
- Onboarding pages: `WelcomePage`, `GoalPickerPage`, `FocusAreaPickerPage`,
  `BodyMapIntroPage`, `NotificationsPage` (5 pages, `OnboardingView`).
- `AuthManager` holds a single `displayName`. Apple's name arrives only on the
  first authorization (else falls back to "Apple User"), Google's comes from
  userinfo, email sign-up takes one "name" field. `RootView.ensureUserProfile`
  creates the local `UserProfile` from `displayName`.
- `RemoteProfile` (`profiles` table) has `id`, `display_name`, points, streak,
  minutes, `last_session_at`. It is a leaderboard row and is not currently
  written at sign-up, so it is not yet a registration marker.

## Design

### 1. Launch flow

```
Fresh install                       Returning device, unregistered account
  Showcase slides (NEW)               Sign in / Sign up
  Goals -> Focus -> Notifications     Name step (no profile row / no name)
  Sign in / Sign up                   Coach-mark tour
  Name step (no profile row / no name)
  Coach-mark tour
```

- `OnboardingGate` keeps owning the pre-auth pages. 3-4 showcase pages are
  added ahead of the existing ones: Body Map screenshots, exercise list with
  animated demos, routines/streak. Showcase pages use static image assets
  (captured from the app in the simulator), no live SceneKit or SwiftData.
  Showcase pages are skippable.
- After the last pre-auth page the user lands on `AuthView`, as today.
- `hasCompletedOnboarding` stays device-level (pre-auth pages run before any
  account exists).

### 2. Name capture and registration

- After sign-in, `RootView` gains a registration gate that fetches the
  `profiles` row for the auth uid through `SupabaseService`. Three outcomes:
  - **Row exists with a name:** registered. Restore first/last name locally,
    skip the name step and the tour, go to Home.
  - **No row, or row without a name:** show a new `NameEntryView` (first name,
    last name; both required, trimmed). Prefill from Apple/Google when they
    supplied a name. On submit, upsert the `profiles` row with the name. That
    upsert is what makes the account "registered". Then start the tour.
  - **Offline / fetch error:** fall back to a local per-account registered
    flag so a flaky connection does not force re-onboarding. The name step
    appears only if no local name exists either.
- The name step applies to Apple, Google and email sign-up alike. Email
  sign-up's single "name" field is removed; the name step replaces it.
  `AuthManager.signUp(name:...)` no longer requires a name up front.
- `AuthManager` stores `firstName` and `lastName` separately.
  `displayName` remains as the computed "First Last" so `TodayView`, profile,
  leaderboard and export code keep working. The `TodayView` greeting uses the
  first name only ("Good morning, First").
- Guests are unaffected: no name step, no registration check.

### 3. Tour flags

- `hasSeenAppGuide` becomes per-account (keyed by `AuthManager.backendID`)
  instead of global. An unregistered account triggers
  `tourCoordinator.restart()`; a registered account does not.
- Sign-out must not clear the device-level `hasCompletedOnboarding`.

### 4. Backend

- `profiles` needs `first_name` and `last_name` columns (nullable, so existing
  rows stay valid; `display_name` continues to be written as "First Last").
- Before writing the migration, inspect the live schema and RLS through the
  Supabase MCP. Applying the migration requires explicit user approval.
- The `profiles` upsert at name submit must satisfy the existing
  `id = auth.uid()` RLS policy.

### 5. Testing

- The routing decision is a pure function:
  `(isSignedIn, isGuest, remoteProfileResult, localFlags) -> {home, nameStep, tour}`.
  Written test-first with Swift Testing (module `BreathRelaxStretch`).
- `AuthManager` tests using the existing `FakeSupabaseAuthenticating` double:
  name persistence, computed `displayName`, Apple/Google prefill, sign-out.
- `SupabaseService` tests for the profile fetch/upsert DTO
  (`first_name` / `last_name` coding keys).
- Simulator verification via the repo's `verify` skill: fresh install path,
  returning-registered path, unregistered-on-onboarded-device path.
- Known pre-existing failures (`CuratedContentIntegrityTests`, UITest-runner)
  are not regressions.

## Decisions

- "Registered" means a Supabase `profiles` row with a name for the auth uid.
- The showcase is pre-auth and the coach-mark tour is post-auth.
- Showcase screenshots are captured from the app itself.
- Showcase slides are skippable.
- Greeting uses first name only.

## Out of scope

- Changing the existing goal / focus-area / notifications pages.
- Reworking App Lock.
- Backfilling names for existing accounts (they hit the name step on next
  sign-in via the "row without a name" path).
