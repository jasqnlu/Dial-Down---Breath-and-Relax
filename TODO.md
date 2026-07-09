# Breath: Relax & Stretch — TODO

Updated 2026-07-06 (rev 4 — consolidated queue: model assignments, Jason tasks, risk register)

Model tags: **Haiku 4.5** = cheap/mechanical · **Sonnet 5** = standard feature/fix work · **Opus 4.8** = complex multi-file features · **Fable 5** = conflict-heavy merges / judgment-heavy work · **Jason** = human-only (Blender, Xcode capabilities, accounts, content).

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
- [x] App Lock toggle (Face ID / Touch ID / passcode)
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
- [x] **Body layer switching** — turns out this was already fully implemented (`BodyMapView`'s Skin/Muscle/Skeleton segmented picker + `BodyLayer.silhouetteFill`/`.highlightColor` in `HumanFigureView.swift`) — the old TODO note calling this unbuilt was stale. **Superseded (rev 4): the layer picker is being REMOVED — see § 1, bodymap merge**

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
- [x] **PaywallView** — Monthly/Annual/Lifetime cards, "Launch Sale" strikethrough pricing (flagged with an `isLaunchPeriod` flag to turn off later — the real charged price always comes live from StoreKit, the strikethrough is just marketing framing), live-computed annual savings %, 7-day trial messaging, restore purchases. **⚠ See § 3 — the strikethrough/trial copy needs a compliance pass before submission**
- [x] **GuidedProgramsView / GuidedProgramDetailView / ContentPacksView** — Day 1 of `proFullReset` is always playable as a free preview; days 2–30 prompt the paywall when `!isPro`. Entry points added: Routines tab (Guided Programs + Content Packs links), Profile → Account ("Upgrade to Breath Pro" banner, hidden once Pro)
- [x] **Paywall trigger** — fires once after the 3rd completed session (`hasSeenInitialPaywall` flag prevents repeats), in both `SessionPlayerView` and `BreathingView`. Made mutually exclusive with the StoreKit review prompt at session 3 specifically (review now fires at 10/25 only) so the two sheets never collide

**Note:** all pricing ($3.99/$24.99/$59.99/$4.99) is placeholder-but-real — it's what StoreKit will actually charge in testing. Change it directly in `Configuration.storekit` before going live; trivial to edit, no code changes needed.

---

## ⚙️ Manual Xcode setup required (code is done, capabilities are not)

None of this can be done from the command line — these features are fully coded but inert until you do the following in Xcode:

- [x] **HealthKit** — HealthKit entitlement is present, and generated Info.plist includes `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` with sleep-aware copy.
- [ ] **iCloud/CloudKit** — target → Signing & Capabilities → add iCloud (check CloudKit) → create container; add Background Modes → Remote notifications
- [ ] **Widget Extension** — File → New → Target → Widget Extension named `BreathWidget`; replace generated files with [BreathWidget/BreathWidget.swift](BreathWidget/BreathWidget.swift); add App Groups capability to *both* the main app and widget targets with a shared group ID; replace the `group.REPLACE_WITH_YOUR_BUNDLE_ID` placeholder in both [WidgetDataService.swift](Breath%20-%20Relax%20%26%20Stretch/Services/WidgetDataService.swift) and `BreathWidget/BreathWidget.swift`
- [ ] **Widget deep link** — add `breath` URL scheme to Info.plist so the widget's "Start Session" button can open the app (handler is written — `DeepLinkRouter` + `.onOpenURL`; just needs the Info.plist URL scheme registered)
- [x] **Calendar (EventKit)** — generated Info.plist includes `NSCalendarsFullAccessUsageDescription` for the "Add Sessions to Calendar" toggle.
- [ ] **Apple Watch app** — File → New → Target → Watch App, name it `BreathWatch`; replace generated files with the three files in [BreathWatch/](BreathWatch/); add `BreathingModels.swift` to the new target's membership (File Inspector → Target Membership) since the watch UI reuses `BreathingPattern`/`BreathPhase`; add HealthKit capability to this target too (for live heart rate)
- [ ] **Watch streak complication** — File → New → Target → Widget Extension embedded in `BreathWatch`, name it `BreathWatchComplication`; replace generated files with [BreathWatchComplication/BreathWatchComplication.swift](BreathWatchComplication/BreathWatchComplication.swift); add the *same* App Group used for `BreathWidget` to this target; update the placeholder group ID in the file
- [ ] **Localization** — `Localizable.xcstrings` is in place with ES/FR/ZH-Hans translations for ~80 strings; no code changes needed since `Text("...")` etc. auto-resolve against the catalog. Have a native speaker review before shipping, and expand coverage to onboarding copy and exercise instructions when there's time
- [ ] **StoreKit Configuration** — Product → Scheme → Edit Scheme → Run → Options tab → StoreKit Configuration → select `Configuration.storekit`. Without this, `StoreManager.loadProducts()` returns an empty list and the paywall shows blank prices
- [ ] **Google Sign-In** — when ready (parked for now): Google Cloud Console → Credentials → Create OAuth client ID → iOS → enter Bundle ID → copy the Client ID into `GoogleAuthService.clientID`. No SPM package, no Info.plist entry needed — that's it
- [ ] **Supabase schema** — real Project URL + anon key are present in `SupabaseService.swift`; still run [supabase_schema.sql](supabase_schema.sql) in the Supabase SQL editor for the live project.
- [ ] **Supabase Auth (Apple provider)** — new since the auth wiring (2026-07-06): Supabase Dashboard → Authentication → Providers → enable **Apple**, set the app's Bundle ID as the client ID; then **re-run [supabase_schema.sql](supabase_schema.sql)** to apply the tightened `auth.uid()` RLS policies (safe to re-run — it drops the old anon-writable ones first). Until both are done, Sign in with Apple still works locally; only the backend token exchange 4xx's (logged, non-fatal) and community uploads stay rejected

---

## ✅ Completed (v0.7 — infrastructure sweep, 2026-07-06)

- [x] **Screen keep-awake during sessions** — `isIdleTimerDisabled` now set while `SessionPlayerView` is up and while a `BreathingView` session is running; previously the phone auto-locked mid-stretch and froze the main-runloop timer
- [x] **Face ID usage string** — `NSFaceIDUsageDescription` added to build settings; App Lock's biometric prompt failed silently on Face ID devices without it (the C1 crash-path commit added Calendar/Health strings but missed this one)
- [x] **PBKDF2 failure hardening** — `pbkdf2()` returns `""` if CommonCrypto errors; `signUp` now refuses to store an empty hash (which any password would have matched) and `signIn` rejects empty computed hashes
- [x] **Account deletion removes the public leaderboard row** — `SupabaseService.deleteProfile(id:)` + best-effort call in `AuthManager.deleteAccount()` *before* the anonymous ID rotates (after rotation the row was unreachable forever); matching delete policy added to `supabase_schema.sql` — **re-run that file (or just the new policy) in the Supabase SQL editor**
- [x] **Removed empty `Views 2` / `Resources 2` folders** — Xcode duplicate-folder accidents; with filesystem-synced groups they'd ship as empty noise

---

## ✅ Completed (v0.8 — engineering queue + Sonnet-5 batch, 2026-07-06)

- [x] **Wire Supabase Auth end-to-end** (Fable 5) — Apple identity token → Supabase session, keychain-persisted + auto-refreshed; `AuthManager.backendID` keys community rows; RLS tightened to `auth.uid()`. Manual steps remain in ⚙️. Design doc: [docs/superpowers/specs/2026-07-06-supabase-auth-and-flexibility-checkins-design.md](docs/superpowers/specs/2026-07-06-supabase-auth-and-flexibility-checkins-design.md)
- [x] **Background-resilient session timers** — wall-clock `phaseEndDate` anchoring in `SessionPlayerView`/`BreathingView`; pause banks remaining time; `scenePhase` catch-up on foreground
- [x] **Shared `SessionRecorder`** — consolidates the ~60 duplicated save/streak/HealthKit/Calendar/Widget lines from both players; covered by `SessionRecorderTests`
- [x] **AuthManager unit tests** — `KeychainStore` seam + injectable `PasswordHasher`; covers validation, duplicates, corrupted credentials, empty-hash paths
- [x] **Flexibility check-ins** (Fable 5) — 4 self-tests × 5 levels; `FlexibilityCheckIn` @Model, Progress card with deltas + step-line chart, 14-day nudge; 13 unit tests + e2e XCUITest (also fixed stale `TEST_TARGET_NAME` in the UITests target)
- [x] **Duration multiplier (0.5×/1×/2×)** (Sonnet 5, `97738e5`) — segmented control in the session player scales every hold time
- [x] **Get-ready countdown between exercises** (Sonnet 5, `fcf76b3` + re-entrancy/cancellation fixes `3963ddc`/`8cba850`/`c849af3`/`48bd8b9`) — 3-2-1 interstitial with next exercise name; "Auto-Skip" toggle in Settings
- [x] **Time-aware Today hero** (Sonnet 5, `5612a22`) — Wake Up (5–11h) / Unwind (20–5h) curated pools via new `GoalMeta` entries
- [x] **Streak freeze + streak-lost alert** (Sonnet 5, `91df7e2` + `29d8ca1`) — 1 token earned per 7 sessions; broken-streak detection on Today appear; restore spends a token, dismiss doesn't
- [x] **Haiku cleanups** — `os.Logger` categories replace `#if DEBUG print`; one shared `ISO8601DateFormatter`; `completionPercent` semantics documented as 0–1

---

## 1 · 🔀 In-flight branches to land (highest value — the work already exists)

Merge order: bodymap → breathing-preview → onboarding-survey → branch triage → page-titles (audits the merged result, runs LAST).

- [ ] **Merge `feature/bodymap-3d-marking` into main** → **Fable 5**. This is the "remove the Skin/Muscle/Skeleton tabs" item: the branch (code-complete T1–T6 at `c00a973`, build + tests green, simulator-verified) replaces the three-layer picker with ONE skin map; strokes hit-test an invisible muscle proxy (`MuscleNameResolver` → ~40 `MuscleGroup`s) and marked muscles glow through the skin in 3D. Deletes `HumanFigureView`, `BodyFigureCanvas`, `MuscleAnatomyCanvas`, `SkeletonAnatomyCanvas`, `AnatomyDrawingHelpers`, `AnnotationStore`, `BodySkeleton.obj`. **The branch diverged at `9184a78` — before Supabase auth, flexibility check-ins, and the Sonnet-5 batch.** Conflict hot spots: `SessionPlayerView.swift`, `TodayView.swift`, `supabase_schema.sql`, `GamificationServiceTests.swift`, `TODO.md`. Resolution rule: keep main's newer feature code; take the branch's body-map deletions/additions wholesale. After merge: full test suite + simulator verify (browse, mark mode at an oblique angle, find-exercises from a marked group). Also lands `docs/BLENDER_MUSCLE_EXPORT.md` + `docs/superpowers/2026-07-05-master-todo.md` on main.
- [ ] **Finish breathing preview (Task 2)** → **Opus 4.8**. Task 1 (`BreathPreviewController` + tests) is committed at `3649fff`; the `BreathingView` wiring sits **half-done and uncommitted** in worktree `.claude/worktrees/agent-ac2c9b9e789ee75c0`. Recover it, finish per [plan](docs/superpowers/plans/2026-07-04-4-breathing-preview.md), discard the off-plan `BreathingPreviewUITests.swift`, merge.
- [ ] **Onboarding survey + facts** → **Opus 4.8**. Per [plan](docs/superpowers/plans/2026-07-04-3-onboarding-survey.md): 5 survey questions interleaved with cited stretching-fact cards; answers pre-mark body-map muscles + pre-fill the reminder hour. **Blocked on the bodymap merge** (needs `MuscleMarkStore`/`MuscleGroup` on main).
- [ ] **Branch triage — ~24 unmerged fix/test branches ship nowhere** → **Opus 4.8**. For each: already re-implemented on main (e.g. `fix/deadline-based-timers`) → delete ref; still valuable → rebase-merge. Likely keepers: `fix/signout-clears-userdefaults`, `fix/email-case-sensitivity`, `fix/apple-signin-email-recovery` (stable Apple user ID never persisted), `fix/seed-exercise-stable-uuid`, `fix/userprofile-dedupe`, `fix/watch-deadline-based-timer` (main only fixed the iOS timers), `test/core-logic-unit-tests`.
- [ ] **Page-title audit + fixes** → **Sonnet 5** (drives the simulator via the repo's `verify` skill). Per [plan](docs/superpowers/plans/2026-07-04-5-page-titles.md): screenshot audit at iPhone SE width, then convention/truncation fixes (tab roots `.large`, pushed pages `.inline`, shorten colliding literals). Titles are being fixed, not removed.

---

## 2 · 🔧 Engineering queue

- [x] **Decide: wire or delete `uploadSession`/`uploadRoutine`** — fixed: dead write methods were removed from `SupabaseService`, and matching insert/update RLS policies were dropped from `supabase_schema.sql`.
- [x] **Exercise cautions shown in-session** — fixed: `SessionPlayerView` renders `CautionCard` on the get-ready screen, and auto-skip does not bypass cautioned exercises.
- [x] **Side-switch cues for unilateral stretches** — fixed: `isBilateral` is seeded/migrated and `SessionPlayerView` emits a haptic + voice "Switch sides" cue at the halfway point.
- [ ] **Background-load the OBJ models** → **Sonnet 5**, after the bodymap merge. First Body Map open parses multi-MB OBJs synchronously on the main thread — seconds-long freeze on older devices. Load templates off-main with a placeholder.
- [ ] **Live Activity / Dynamic Island for active sessions** → **Opus 4.8 + Jason**. Remaining hold time on the lock screen; needs the widget-extension target to exist first (⚙️ section).
- [x] **Data export completeness** — fixed: CSV/JSON export includes sessions, routines, profile totals, badges, and streak-freeze state.
- [x] **`seedDataVersion` bumps even when `context.save()` fails** — fixed: migration versions now advance only after successful saves when changes were made.
- [x] **`restorePurchases` swallows failures** — fixed: `StoreManager.restorePurchases()` publishes `restoreError`, and `PaywallView` shows a Restore Failed alert.
- [x] **Rename the "2FA" toggle** — fixed 2026-07-08: live UI says App Lock, the historical TODO wording was corrected, and `AuthManager` now migrates `auth.twoFAEnabled` to `auth.appLockEnabled`.

---

## 3 · 🚨 App Store / compliance risk register (fix BEFORE TestFlight / submission)

Things that will bite later if ignored — ordered by severity:

- [x] **No `PrivacyInfo.xcprivacy` anywhere** — fixed: main app has `PrivacyInfo.xcprivacy` declaring UserDefaults reasons CA92.1/1C8F.1 and collected leaderboard profile/stats data. Widget/Watch manifests are still tied to creating those targets.
- [x] **Paywall compliance (Guideline 3.1.2)** — code fixed: `PaywallView` uses StoreKit display prices, derives free-trial copy from `product.subscription?.introductoryOffer`, has no fabricated strikethrough prices, surfaces restore failures, and links bundled Terms/Privacy documents. Jason still needs hosted legal URLs before public launch.
- [x] **In-app Privacy Policy makes a false claim** — fixed 2026-07-08: `ProfileSettingsTab` now says local data stays on-device and only feature-required profile/auth data may be sent when the user opts into community features or supported sign-in.
- [ ] **Localization is ~36% complete across 4 declared languages** → **Jason decision**, then **Sonnet 5**. es/fr/zh users get mixed-language UI. Either finish coverage (+ native-speaker pass) or remove the languages from `knownRegions` until ready.
- [x] **"Female" body-type picker promises a model that doesn't exist** — fixed: picker says "Female (coming soon)" and the footer clarifies it currently uses the same targeting anatomy.
- [ ] **Migration matches exercises by name** → **Opus 4.8** (fold into branch triage — pairs with `fix/seed-exercise-stable-uuid`). A user renaming a seed exercise breaks migration for that row forever; key on stable UUIDs.
- [ ] **Placeholder credentials still shipping** — `group.REPLACE_WITH_YOUR_BUNDLE_ID` (`WidgetDataService.swift:15`, widget/watch source files) and Google Client ID. All inert but must be resolved via ⚙️ before those features go live (**Jason**).
- [ ] **~7 MB of OBJs in the bundle** → **Sonnet 5**, low priority, after the bodymap merge settles. Convert to `.scn`/`.usdz` (5–10× smaller); pairs with the background-loading item in § 2.

---

## 4 · 🧑‍🎨 Jason's queue (human-only)

### A. Blender — per-muscle hitbox export (unblocks accurate marking; **no code change needed after**)

The merged `BodyMuscle.obj` (single `o AnatomyExport`) makes marking fall back to a coarse position heuristic. A per-muscle re-export switches on full accuracy + muscle glow automatically. Full guide: [docs/BLENDER_MUSCLE_EXPORT.md](docs/BLENDER_MUSCLE_EXPORT.md) (lands with the bodymap merge). Summary:

1. Open the Z-Anatomy `.blend`; in the Outliner select the **muscular-system collection**. **Do not join objects** — each muscle keeps its own name.
2. Decimate first: add a **Decimate (Collapse)** modifier, ratio ≈ 0.1, to all muscle objects and **Apply** (target < 8 MB total — the proxy is never drawn, heavy geometry is pure waste).
3. `File ▸ Export ▸ Wavefront (.obj)`: **Limit to Selected Only ON**, **OBJ Objects ON** (this is what preserves per-muscle `o` names), **Apply Modifiers ON**, **Triangulated Mesh ON**, Forward **−Z**, Up **Y** (must match the skin export so the proxy aligns; scale doesn't matter — the app re-normalises).
4. Replace `Breath - Relax & Stretch/Resources/Models3D/BodyMuscle.obj` and verify:
   `grep -c "^o " BodyMuscle.obj` → **hundreds** = success; **1** = still merged, redo step 3.
   Spot-check names (`grep "^o " BodyMuscle.obj | head`) — expect `o Gastrocnemius.l` style; if a name isn't recognised, add a keyword to `MuscleNameResolver`'s table.

**Resources:** Z-Anatomy project (z-anatomy.com; .blend sources at github.com/LluisV/Z-Anatomy) · Blender manual → File Formats → Wavefront OBJ (export options) · Blender manual → Modifiers → Decimate · this repo's `docs/BLENDER_MUSCLE_EXPORT.md` + the Claude memory note `bodymap_3d_skin_architecture.md` (normalisation/alignment conventions).

### B. Blender — later / optional

- [ ] **Female body mesh** — Z-Anatomy includes one; export the female skin with the same settings/pipeline as `BodyMale.obj` (the code re-normalises: bbox-centre pivot, height → 2.0). Unblocks the honest version of the body-type picker (§ 3).
- [ ] **Lower-poly skin re-export** — if/when the `.usdz` conversion happens (§ 3 last item), a decimated skin keeps quality while shrinking the bundle further.

### C. Xcode capabilities & accounts

Everything in the **⚙️ Manual Xcode setup** section above — HealthKit, iCloud, Widget target + App Group, `breath://` URL scheme, Watch targets, StoreKit Configuration scheme step, Google Client ID, Supabase credentials + Apple provider + schema re-run.

### D. UI polish queue (with tips)

- [x] **Session progress bar is exercise-granular** — fixed 2026-07-08: `SessionPlayerView` now computes elapsed seconds across scaled exercise durations and animates progress linearly each tick.
- [x] **`BreathingCircle` in the session player pulses at a fixed 4s** — fixed 2026-07-08: the session-player breath visual now derives cadence from the scaled breathing exercise duration instead of using one hardcoded pulse length. A richer future pass could still share the full phase-labeled `BreathingView` model.
- [x] **Completion overlay vs floating tab bar** — fixed 2026-07-08: `BreathingView` gives the completion overlay a high z-index so it reliably sits above the tab chrome.
- [x] **Paywall stacks directly onto the session-3 summary** — fixed 2026-07-08: session completion now sets a `pendingInitialPaywall` flag and requests presentation from `HomeView` after the reward screen is dismissed / the app returns active.
- [x] **"No Exercises" empty state is a dead end** — fixed 2026-07-08: the player empty state has a "Browse Exercises" action that dismisses and switches the shell to the Exercises tab.
- [ ] **General polish pass** — buttons mix `Capsule` and `RoundedRectangle(14)` shapes across Breathing/Paywall/Onboarding; pick one radius token. Custom-pattern editor now uses a medium detent and breathing phase transitions have light haptics.

### E. Content

- [ ] **Film exercise demo videos** — the `localVideoName` slot + "Video coming soon" placeholder card are live; drop bundled `.mp4`s and set the field in seed data.
- [ ] **Set real IAP pricing** in `Configuration.storekit` before going live (no code changes needed).
- [ ] **Native-speaker pass** on the ES/FR/ZH-Hans strings (currently AI-translated).

---

## 5 · 🌫 Deferred (deliberate)

- **Mac Catalyst / visionOS** — after the iPhone app is solid; App Store readiness gaps close first.
- **`BorrowRoutineView` placeholder Supabase URL** — resolves itself when Supabase credentials are configured (⚙️).
- **Exercise-instruction localization** (152 exercises × 3 languages) — separate, much larger effort than the UI-string catalog.

---

## 🐛 Known Bugs / Tech Debt (history)

- [x] Body map annotation eraser — fixed: `blendMode(.destinationOut)` inside isolated `drawLayer`
- [x] `SessionPlayerView` timer leak — fixed: `sessionActive` flag set in `.onDisappear`
- [x] Unescaped quotes in `ProfileSettingsTab.swift` footer string broke the build — fixed
- [x] Missing `import Combine` in `StickFigureView.swift` (`Timer.publish().autoconnect()`) broke the build — fixed
- [x] Invalid `Section("Title") { } footer: { }` calls (2×) in `ProfileSettingsTab.swift` — SwiftUI doesn't support a footer on the string-title initializer; switched to `Section { } header: { } footer: { }` — fixed
- [x] ~~`AuthManager.signUp` hashes password with SHA-256 (fast hash)~~ — stale note, it already uses PBKDF2 (100k rounds, SHA-256 PRF, 16-byte random salt) via CommonCrypto
- [x] Unit tests — Swift Testing suites now cover `GamificationService`, `SharePayload`s, `SessionRecorder`, `AuthManager` (keychain seam), `SupabaseSession`, flexibility check-ins, seed data v4, `GoalMeta`/`TodayView` time logic, and `SessionPlayerView.scaledDuration`. Remaining gap: body-map stores (`MuscleMarkStore`/`MuscleNameResolver` tests exist on the bodymap branch and land with its merge)

---

## 🗓 Suggested Sprint Order

| Sprint | Focus |
|--------|-------|
| 1–10 | ✅ All shipped (see completed sections above) |
| 11 | Land in-flight branches: bodymap merge → breathing preview → onboarding survey → branch triage → page titles |
| 12 | Engineering queue § 2 (cautions in-session, uploads decision, OBJ loading, small guards) |
| 13 | Compliance pack § 3 (privacy manifest, paywall, policy pages) + Jason's ⚙️ capability wiring |
| 14 | Jason content (Blender re-export, videos, pricing, localization pass) |
| 15 | TestFlight + final App Store submission prep |
