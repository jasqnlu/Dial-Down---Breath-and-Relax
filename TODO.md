# Breath: Relax & Stretch — TODO

Updated 2026-07-06 (rev 3 — infrastructure sweep)

---

## ✅ Completed (v0.1)

- [x] Core SwiftData models (Exercise, Routine, Session, UserProfile, BodyPart)
- [x] Body map with human silhouette + region tap → exercise filter
- [x] Drawing annotation overlay (pen / highlighter / eraser / sensation colours)
- [x] Exercise list with search + type filter
- [x] Routine builder (create, reorder, delete)
- [x] Borrow public routines (fork + own)
- [x] Session player (timer, progress, points)
- [x] Session summary screen
- [x] Gamification — points, streak, badges
- [x] Supabase REST backend (exercises, routines, sessions)
- [x] Sign in with Apple + email/password auth
- [x] Two-Factor Authentication toggle
- [x] Sign Out
- [x] Dark mode polish (no hardcoded colours)
- [x] VoiceOver accessibility labels
- [x] Haptic feedback (session transitions + auth)
- [x] Ambient sound + completion chime
- [x] Profile view with stats + badges

---

## ✅ Completed (v0.2)

- [x] Onboarding flow — 4-page (Welcome → Goal Picker → Body Map intro → Notification permission); shown once via @AppStorage gate
- [x] Push notifications — UNUserNotificationCenter daily reminder; wired to Settings toggle + time/days steppers in Profile
- [x] Breathing exercises — standalone Breathe tab; 4 patterns (Box, 4-7-8, Belly, Energising); animated circle, phase labels, saves stats
- [x] Progress charts — Swift Charts bar chart (weekly minutes), streak calendar, cumulative points line chart
- [x] Custom exercise creation — form with name/type/duration/difficulty/body parts/instructions; saves to SwiftData
- [x] Notification delivery — fully wired: requestPermission on first enable, reschedule on time/days change
- [x] Data export — Export My Data → generates CSV or JSON of all sessions → ShareLink to save/share
- [x] Exercise video/GIF preview — AVKit VideoPlayer shown in ExerciseDetailView when `mediaURL` is set
- [x] Profile photo — PhotosPicker → downscale to 512×512 → saved to Documents; shown in profile header avatar
- [x] Seed data expansion — 35 exercises total (was 10); covers all body regions

---

## ✅ Completed (v0.3)

- [x] **Bug sweep** — pose keyframes added to 17 stretch exercises that had none (37/44 exercises now animated); `seedDataVersion` migration backfills poses for existing users; per-weekday notification scheduling (`UNCalendarNotificationTrigger` × 7) replaced the old no-op `daysPerWeek` param; `RoutineBuilderView` supports editing (not just creating); dead `BodyHighlightService` deleted
- [x] **Onboarding goals → "For You"** — `ForYouSection` on the Exercises tab reads `@AppStorage("onboardingGoals")`, surfaces a curated, interleaved set of exercises per goal, plus a one-tap Quick Session; goals are editable later from Profile → Settings
- [x] **StoreKit review prompt** — `requestReview()` fires after sessions 3, 10, and 25 (shared `totalSessionsCompleted` counter), 1.5s after the summary screen appears
- [x] **Voice cues** — `VoiceCueService` (AVSpeechSynthesizer) speaks the exercise name at the start of each session exercise, and "Inhale" / "Hold" / "Exhale" at each breathing phase transition; toggle in Profile → Settings → Session, off by default
- [x] **HealthKit** — `HealthKitService` logs stretch sessions as Flexibility workouts (with estimated active-energy) and breathing sessions as Mindful Minutes; "Connect Apple Health" row in Settings; data flows to Google Health/Samsung Health/etc. automatically since they read from Apple Health
- [x] **iCloud / CloudKit sync** — `ModelConfiguration(cloudKitDatabase: .automatic)`; all four `@Model` classes given inline property defaults (required for CloudKit schema compatibility)
- [x] **WidgetKit** — `BreathWidget` target code written (small Streak widget + medium Stats widget with quick-start deep link); shares data via `WidgetDataService` → App Group `UserDefaults`
- [x] **Routine sharing** — `RoutineSharePayload` encodes a routine (name + exercise names) as a `breath://routine?data=...` link; `ShareLink` swipe action in `RoutineListView`; `ImportRoutineView` confirms matched/unmatched exercises before saving
- [x] **Widget URL scheme handler** — `DeepLinkRouter` (`ObservableObject`) parses `breath://quick-session` and `breath://routine?data=...`; wired via `.onOpenURL` in the app entry point; `HomeView` presents the right sheet
- [x] **Session history detail view** — `SessionDayDetailView` sheet; tapping a day with a session in the streak calendar or year heatmap shows time, duration, points, and resolved exercise names (or breathing pattern + rounds)
- [x] **Full-year activity heatmap** — new "Year in Review" section in `ProgressChartsView`: 53-week × 7-day GitHub-style grid, color intensity by session count, auto-scrolled to today, tap a day for detail
- [x] `Session` model gained `exerciseIDs: [UUID]`, `sessionLabel: String?`, `roundsCompleted: Int` so history/detail views can show what was actually done instead of just points/minutes

---

## ✅ Completed (v0.4 — "Nice to Have" batch)

- [x] **Custom breathing pattern creator** — new `.custom` case on `BreathingPattern`; `CustomPatternEditorView` sheet (steppers for inhale/hold/exhale/hold2, 0–20s); values persist via `UserDefaults`, picked up automatically by the existing phase machine
- [x] **Calendar integration** — `CalendarService` (EventKit): opt-in "Add Sessions to Calendar" toggle in Settings logs each completed session as an event; `suggestFreeSlot()` surfaces a "You're free at 2:30 PM" banner on the Exercises tab
- [x] **Sleep-aware suggestions** — `HealthKitService` gained read access + `lastNightSleepHours()`; Exercises tab shows a banner offering a gentler (difficulty-1) session when sleep was under 7h
- [x] **Streak card image export** — `StreakCardShareSheet` renders a gradient card (streak/points/minutes) via `ImageRenderer`, shareable through the system share sheet; share-square button in Progress toolbar
- [x] **Social / community scaffold** — `RemoteProfile` DTO + `SupabaseService.uploadProfile()`/`fetchLeaderboard()`; `LeaderboardView`; `ChallengePayload` shares streak/points as a `breath://challenge?data=...` link with a "Challenge a Friend" button in Profile → Account; `ChallengeInviteView` handles incoming invites and routes into a Quick Session. Like routine borrowing, the leaderboard won't show real data until Supabase credentials are configured
- [x] **Apple Watch app (code)** — `BreathWatch/` (watch app: pattern picker, glanceable timer, `HKWorkoutSession`-backed live heart rate during the session) + `BreathWatchComplication/` (circular/rectangular streak complication, reads the same App Group data as the iOS widget)
- [x] **Localization infrastructure** — `Localizable.xcstrings` String Catalog with ~80 of the highest-traffic strings (tab names, common actions, breathing patterns, settings, progress, community, onboarding) translated into Spanish, French, and Simplified Chinese; `es`/`fr`/`zh-Hans` added to the project's `knownRegions`. **AI-translated — get a native speaker pass before shipping.** Exercise instruction text in `SeedData.json` (44 exercises) is not yet localized — that's a separate, much larger effort
- [x] **Body layer switching** — turns out this was already fully implemented (`BodyMapView`'s Skin/Muscle/Skeleton segmented picker + `BodyLayer.silhouetteFill`/`.highlightColor` in `HumanFigureView.swift`) — the old TODO note calling this unbuilt was stale

**Discovered while implementing the above (not new work, just corrections):**
- `RoutineSharePayload`/`ChallengePayload` share near-identical base64 URL-encode/decode logic. Left un-DRY'd for now, consistent with this codebase's existing tolerance for that kind of small duplication (e.g. the repeated `#if DEBUG` SwiftData-save-error blocks) — revisit if a third payload type shows up.
- The "AuthManager uses fast SHA-256 hashing" bug note below was stale — it already uses PBKDF2 (100k rounds). Corrected.

---

## ✅ Completed (v0.5 — High Priority batch)

- [x] **App icon** — generated programmatically (CoreGraphics script, not hand-designed): gradient + concentric circles echoing the in-app breathing animation; light/dark/tinted 1024×1024 variants wired into `AppIcon.appiconset/Contents.json`. Good enough to unblock submission; consider a real designer pass later
- [x] **App Store screenshots** — 6.9" set captured (7 screens: auth, body map, profile/community, exercises + For You, active breathing session, exercise detail, muscle-layer body map) in `AppStoreScreenshots/6.9-inch/`; 6.3" set started, finished by Jason directly in the simulator
- [x] **Google Sign-In (code)** — `GoogleAuthService` implements full OAuth 2.0 Authorization Code + PKCE via `ASWebAuthenticationSession` directly — **no GoogleSignIn SDK / SPM dependency, no Info.plist URL scheme needed** (the session intercepts its own redirect). `AuthManager.handleGoogleSignIn(name:email:)` added. Button in `AuthView` auto-enables once a real Client ID replaces the placeholder in `GoogleAuthService.clientID`. **Parked per Jason's call** — wants to finalize other features before dealing with Google Cloud Console setup
- [x] **Supabase schema** — [supabase_schema.sql](supabase_schema.sql), ready to paste into the Supabase SQL editor in one shot: `exercises`, `routines`, `sessions`, `profiles` tables with RLS policies matching the app's actual (no-real-auth-yet) security model, documented honestly in the file's header comment

---

## ✅ Completed (v0.6 — Monetization)

- [x] **StoreKit 2 products** — [Configuration.storekit](Breath%20-%20Relax%20%26%20Stretch/Configuration.storekit) for local testing: `pro_monthly` ($3.99, 7-day free trial), `pro_annual` ($24.99, 7-day free trial), `pro_lifetime` ($59.99 one-time, priced above annual as requested), `pack_deskworker` + `pack_athlete_recovery` ($4.99 one-time each)
- [x] **StoreManager** — StoreKit 2 `ObservableObject`: loads products, purchases, restores, listens to `Transaction.updates`, computes `isPro`/`hasLifetime`/`owns(productID:)` from `Transaction.currentEntitlements`
- [x] **GuidedProgram** — `proFullReset` is a real 30-day structure generated from the existing `GoalMeta` exercise pools (rotating offset, not hand-authored filler); `starterProgram(goalIDs:)` is a free 3-day program personalized from the user's onboarding goals — this *is* the "quick starter survey → small program" since onboarding's goal picker already serves as the survey
- [x] **ContentPack** — 2 packs (Desk Worker, Athlete Recovery), each a curated list of existing exercises gated behind its own non-consumable IAP; verified every referenced exercise name actually exists in `SeedData.json`
- [x] **PaywallView** — Monthly/Annual/Lifetime cards, "Launch Sale" strikethrough pricing (flagged with an `isLaunchPeriod` flag to turn off later — the real charged price always comes live from StoreKit, the strikethrough is just marketing framing), live-computed annual savings %, 7-day trial messaging, restore purchases
- [x] **GuidedProgramsView / GuidedProgramDetailView / ContentPacksView** — Day 1 of `proFullReset` is always playable as a free preview; days 2–30 prompt the paywall when `!isPro`. Entry points added: Routines tab (Guided Programs + Content Packs links), Profile → Account ("Upgrade to Breath Pro" banner, hidden once Pro)
- [x] **Paywall trigger** — fires once after the 3rd completed session (`hasSeenInitialPaywall` flag prevents repeats), in both `SessionPlayerView` and `BreathingView`. Made mutually exclusive with the StoreKit review prompt at session 3 specifically (review now fires at 10/25 only) so the two sheets never collide

**Note:** all pricing ($3.99/$24.99/$59.99/$4.99) is placeholder-but-real — it's what StoreKit will actually charge in testing. Change it directly in `Configuration.storekit` before going live; trivial to edit, no code changes needed.

---

## ⚙️ Manual Xcode setup required (code is done, capabilities are not)

None of this can be done from the command line — these features are fully coded but inert until you do the following in Xcode:

- [ ] **HealthKit** — target → Signing & Capabilities → add HealthKit; add `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` to Info.plist (share description should now also mention sleep, since `HealthKitService` reads sleep analysis too)
- [ ] **iCloud/CloudKit** — target → Signing & Capabilities → add iCloud (check CloudKit) → create container; add Background Modes → Remote notifications
- [ ] **Widget Extension** — File → New → Target → Widget Extension named `BreathWidget`; replace generated files with [BreathWidget/BreathWidget.swift](BreathWidget/BreathWidget.swift); add App Groups capability to *both* the main app and widget targets with a shared group ID; replace the `group.REPLACE_WITH_YOUR_BUNDLE_ID` placeholder in both [WidgetDataService.swift](Breath%20-%20Relax%20%26%20Stretch/Services/WidgetDataService.swift) and `BreathWidget/BreathWidget.swift`
- [ ] **Widget deep link** — add `breath` URL scheme to Info.plist so the widget's "Start Session" button can open the app (handler is written — `DeepLinkRouter` + `.onOpenURL`; just needs the Info.plist URL scheme registered)
- [ ] **Calendar (EventKit)** — add `NSCalendarsFullAccessUsageDescription` to Info.plist, or the "Add Sessions to Calendar" toggle's access request will silently fail
- [ ] **Apple Watch app** — File → New → Target → Watch App, name it `BreathWatch`; replace generated files with the three files in [BreathWatch/](BreathWatch/); add `BreathingModels.swift` to the new target's membership (File Inspector → Target Membership) since the watch UI reuses `BreathingPattern`/`BreathPhase`; add HealthKit capability to this target too (for live heart rate)
- [ ] **Watch streak complication** — File → New → Target → Widget Extension embedded in `BreathWatch`, name it `BreathWatchComplication`; replace generated files with [BreathWatchComplication/BreathWatchComplication.swift](BreathWatchComplication/BreathWatchComplication.swift); add the *same* App Group used for `BreathWidget` to this target; update the placeholder group ID in the file
- [ ] **Localization** — `Localizable.xcstrings` is in place with ES/FR/ZH-Hans translations for ~80 strings; no code changes needed since `Text("...")` etc. auto-resolve against the catalog. Have a native speaker review before shipping, and expand coverage to onboarding copy and exercise instructions when there's time
- [ ] **StoreKit Configuration** — Product → Scheme → Edit Scheme → Run → Options tab → StoreKit Configuration → select `Configuration.storekit`. Without this, `StoreManager.loadProducts()` returns an empty list and the paywall shows blank prices
- [ ] **Google Sign-In** — when ready (parked for now): Google Cloud Console → Credentials → Create OAuth client ID → iOS → enter Bundle ID → copy the Client ID into `GoogleAuthService.clientID`. No SPM package, no Info.plist entry needed — that's it
- [ ] **Supabase credentials** — run [supabase_schema.sql](supabase_schema.sql) in the Supabase SQL editor, then copy Project URL + anon key into `SupabaseService.swift`

---

## ✅ Completed (v0.7 — infrastructure sweep, 2026-07-06)

- [x] **Screen keep-awake during sessions** — `isIdleTimerDisabled` now set while `SessionPlayerView` is up and while a `BreathingView` session is running; previously the phone auto-locked mid-stretch and froze the main-runloop timer
- [x] **Face ID usage string** — `NSFaceIDUsageDescription` added to build settings; App Lock's biometric prompt failed silently on Face ID devices without it (the C1 crash-path commit added Calendar/Health strings but missed this one)
- [x] **PBKDF2 failure hardening** — `pbkdf2()` returns `""` if CommonCrypto errors; `signUp` now refuses to store an empty hash (which any password would have matched) and `signIn` rejects empty computed hashes
- [x] **Account deletion removes the public leaderboard row** — `SupabaseService.deleteProfile(id:)` + best-effort call in `AuthManager.deleteAccount()` *before* the anonymous ID rotates (after rotation the row was unreachable forever); matching delete policy added to `supabase_schema.sql` — **re-run that file (or just the new policy) in the Supabase SQL editor**
- [x] **Removed empty `Views 2` / `Resources 2` folders** — Xcode duplicate-folder accidents; with filesystem-synced groups they'd ship as empty noise

---

## 🔴 High Priority — engineering queue (model recommendations noted)

- [ ] **Wire Supabase Auth end-to-end** — `signInWithApple(identityToken:)` is written but unused; every request uses the anon key, so all write policies are anon-writable (leaderboard spoofable, public routines editable by anyone — documented in `supabase_schema.sql`). Wire the Apple identity token through `AuthManager`, persist/refresh the access token (currently in-memory only, expires ~1h), then tighten RLS to `auth.uid()`. Blocks shipping community features publicly. → **Opus 4.8 or Fable** (security-critical, cross-cutting: AuthManager + SupabaseService + schema)
- [x] **Background-resilient session timers** — `SessionPlayerView`/`BreathingView` now anchor to a wall-clock `phaseEndDate` instead of decrementing a tick counter, so a backgrounded app (call, app-switch) no longer freezes the countdown while real time keeps passing. Pause/resume banks the remaining interval; a `scenePhase == .active` handler catches up (advancing through however many exercises/phases elapsed) on return to the foreground.
- [x] **Extract a shared `SessionRecorder`** — new `Services/SessionRecorder.swift` consolidates the ~60 duplicated lines (Session insert, profile/streak/badges, HealthKit, Calendar, Widget write) that `SessionPlayerView` and `BreathingView` each drove independently; both views now call `SessionRecorder.record(...)`. Covered by `SessionRecorderTests.swift` (in-memory `ModelContainer`).
- [ ] **Decide: wire or delete `uploadSession`/`uploadRoutine`** — written, never called; sessions/routines tables exist but receive nothing. If cross-device sync is the plan, wire them behind Supabase Auth; otherwise delete the dead paths. → **Sonnet 5** (after the auth task lands)
- [x] **AuthManager unit tests** — extracted a `KeychainStore` protocol seam (`SecItemKeychainStore` for production, `FakeKeychainStore` in tests) and made the PBKDF2 hasher injectable (`PasswordHasher` typealias) so failures can be simulated deterministically. `AuthManagerTests.swift` covers signUp/signIn validation, duplicate accounts, corrupted stored credentials (missing separator / invalid hex salt), and empty-hash paths on both the signUp and signIn side. Suite is `.serialized` since `AuthManager` persists to the process-global `UserDefaults.standard`.

## 🟡 Cleanups (cheap, batchable)

- [ ] Replace `#if DEBUG print(...)` blocks with `os.Logger` categories → **Haiku 4.5**
- [ ] Reuse one `ISO8601DateFormatter` in `SupabaseService.uploadSession` (creates two per call) → **Haiku 4.5**
- [ ] `Session.completionPercent` semantics: app writes 0–1, schema check allows 0–100 — pick one and document → **Haiku 4.5**

---

## 🌿 Bend-inspired features (competitive parity)

Features the Bend stretching app has that we don't; ordered by value-for-effort:

- [ ] **Side-switch cues for unilateral stretches** — Bend splits e.g. "Neck Tilt" into left/right halves with a spoken "switch sides" cue mid-exercise. We already have mirrored L/R seed exercises; add an `isBilateral` flag so the player runs half the duration per side with a haptic + `VoiceCueService` cue. → **Opus 4.8** (touches seed data model + player)
- [ ] **Duration multiplier (0.5×/1×/2×)** — Bend's single best-loved control: one segmented control before starting a routine scales every hold time. Trivial to pipe through `SessionPlayerView` as a multiplier on `durationSeconds`. → **Sonnet 5**
- [ ] **Get-ready countdown between exercises** — Bend gives a 3-2-1 interstitial with the next exercise's name/preview instead of hard-cutting. Slot into `advanceToNext()` as a short `.transition` phase. → **Sonnet 5**
- [ ] **Time-aware daily routine on Today tab** — Bend leads with one tappable "Your daily stretch" (Wake Up in the morning, Unwind at night). We have `ForYouSection` + `GoalMeta` pools; add a time-of-day pick and make it the Today tab hero. → **Sonnet 5**
- [ ] **Streak freeze / repair** — Bend (like Duolingo) lets a missed day be repaired; softens the harshest churn moment. One earned "freeze" token per N sessions, consumed automatically in `GamificationService.updateStreak`. → **Sonnet 5** (pure logic + tests)
- [ ] **Live Activity / Dynamic Island for active sessions** — remaining hold time on the lock screen; pairs perfectly with the backgrounding fix above. Needs a widget-extension target first (see Manual Xcode setup). → **Opus 4.8 + Jason** (ActivityKit code + target/entitlement in Xcode)
- [ ] **Flexibility check-ins** — Bend's periodic "how far can you reach?" self-test with progress over time; big differentiator but a real feature (new model + views + charts). → **Fable/Opus 4.8, plan first**

---

## 🎨 UI queue — assigned to Jason (with tips)

- [ ] **Session progress bar is exercise-granular** — `ProgressView(value: Double(currentIndex), total: Double(exercises.count))` jumps in whole-exercise steps. Tip: feed it `completedSeconds / totalSeconds` and wrap updates in `withAnimation(.linear(duration: 1))` so it glides once per tick.
- [ ] **`BreathingCircle` in the session player pulses at a fixed 4s** regardless of the exercise's actual breathing pattern. Tip: either drive it from the same phase durations `BreathingView` uses, or swap in the phase-labeled circle so "Inhale/Exhale" text matches the motion — mismatched breathing pacing is the kind of thing wellness-app reviews call out.
- [ ] **Completion overlay vs floating tab bar** — `BreathingView`'s completion overlay renders inside the tab's ZStack, so the floating `CustomTabBar` stays visible above it. Tip: present completion as `.fullScreenCover` (or raise its `zIndex` above the bar) so the moment feels like a reward screen, not a banner behind chrome. (Remember the per-page `.floatingTabBarClearance()` convention.)
- [ ] **Paywall stacks directly onto the session-3 summary** — sheet-over-summary right after a win feels punitive. Tip: set a `pendingPaywall` flag and present it on the *next* app foreground or Home visit instead; conversion literature consistently favors "next natural pause" over "interrupt the reward".
- [ ] **"No Exercises" empty state is a dead end** — the `ContentUnavailableView` in the player has only an X. Tip: `ContentUnavailableView` takes an `actions:` builder — add a "Browse Exercises" button that dismisses and switches to the Exercises tab.
- [ ] **General polish pass** — buttons mix `Capsule` and `RoundedRectangle(14)` shapes across Breathing/Paywall/Onboarding; pick one radius token. Consider `.presentationDetents([.medium])` for the custom-pattern editor (it's a small form under a full sheet), and a light haptic on each breath-phase transition (you already have the generators prepared).

---

## 🟡 Medium Priority

All caught up — see ✅ Completed (v0.3) above. Next candidates live in 🟢 Nice to Have.

---

## 🟢 Nice to Have

Everything from the original list is done as of v0.4 (see above) except two, deliberately deferred:

- [ ] **Skeleton/muscle overlay** — actual anatomically-correct SVG paths per muscle group, replacing the current polygon regions + recolored silhouette. Needs real vector art assets (not something to hand-roll as code) — find/commission anatomical SVGs before attempting this
- [ ] **Mac Catalyst / visionOS** — deliberately deferred per this file's own "after iPhone is solid" guidance; App Store readiness gaps (icon, screenshots, Google Sign-In, real Supabase backend) should close first

---

## 💰 Monetization

Done — see ✅ Completed (v0.6) above. Needs the StoreKit Configuration scheme step (⚙️ above) before it actually works in a build.

---

## 🐛 Known Bugs / Tech Debt

- [x] Body map annotation eraser — fixed: `blendMode(.destinationOut)` inside isolated `drawLayer`
- [x] `SessionPlayerView` timer leak — fixed: `sessionActive` flag set in `.onDisappear`
- [x] Unescaped quotes in `ProfileSettingsTab.swift` footer string broke the build — fixed
- [x] Missing `import Combine` in `StickFigureView.swift` (`Timer.publish().autoconnect()`) broke the build — fixed
- [x] Invalid `Section("Title") { } footer: { }` calls (2×) in `ProfileSettingsTab.swift` — SwiftUI doesn't support a footer on the string-title initializer; switched to `Section { } header: { } footer: { }` — fixed
- [x] ~~`AuthManager.signUp` hashes password with SHA-256 (fast hash)~~ — stale note, it already uses PBKDF2 (100k rounds, SHA-256 PRF, 16-byte random salt) via CommonCrypto
- [ ] `BorrowRoutineView` uses placeholder Supabase URL — real fetch will fail until `.env`-equivalent credentials are configured
- [~] Unit tests — **first batch landed** (Swift Testing, not XCTest — the test target was already scaffolded for `import Testing`): `GamificationServiceTests` (points/streak/badge math) + `SharePayloadTests` (`RoutineSharePayload`/`ChallengePayload` URL-safe-base64 round trips & malformed-input handling). 31 cases, all green via `xcodebuild test` on the iPhone 17 sim. Still uncovered: `AuthManager` (keychain-backed — needs a test seam to avoid touching the real keychain) and the body-map `AnnotationStore` (`@MainActor` UI state)

---

## 🗓 Suggested Sprint Order

| Sprint | Focus |
|--------|-------|
| 1 | Onboarding + push notifications ✅ |
| 2 | Breathing exercise module ✅ |
| 3 | Progress charts (Swift Charts) ✅ |
| 4 | Custom exercise creation ✅ |
| 5 | Data export + profile photo ✅ |
| 6 | Bug sweep + onboarding goals + StoreKit review + voice cues ✅ |
| 7 | HealthKit + iCloud + WidgetKit (code) ✅ — Xcode capability wiring ⬜ |
| 8 | Custom breathing patterns + Calendar + sleep suggestions + streak cards + community scaffold + Watch app (code) + localization ✅ — Xcode/capability wiring for Watch + Calendar ⬜ |
| 9 | App icon + screenshots + Google Sign-In (code) + Supabase schema ✅ — StoreKit/Google Cloud/Supabase account setup ⬜ |
| 10 | Monetization: StoreKit products, paywall, guided programs, content packs ✅ — StoreKit Configuration scheme step ⬜ |
| 11 | TestFlight + final App Store submission prep |
