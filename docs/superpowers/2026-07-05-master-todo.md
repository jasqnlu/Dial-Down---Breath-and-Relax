# Master TODO — Remaining Work + App Audit

**Date:** 2026-07-05
**Specs:** `docs/superpowers/specs/2026-07-04-bodymap-content-overhaul-design.md` (approved)
**Plans:** `docs/superpowers/plans/2026-07-04-{1..5}-*.md` (per-branch, step-by-step TDD)
**Progress ledger:** `.superpowers/sdd/progress.md`

---

## Part A — Status snapshot

| Branch | State |
|---|---|
| `feature/exercise-library` | ✅ **COMPLETE + reviewed** at `9184a78` (MuscleGroup vocabulary, 152-exercise seed v4, stick-figure/YouTube removal, local-video placeholder card, v4 migration) |
| `feature/bodymap-3d-marking` | 🔶 In progress. Task 1/6 (MuscleNameResolver) implemented at `373ae8c`, tests green, **not yet task-reviewed** |
| `feature/breathing-preview` | 🔶 In worktree `.claude/worktrees/agent-ac2c9b9e789ee75c0`. Task 1/2 (BreathPreviewController + tests) committed at `3649fff`; Task 2 (BreathingView wiring) half-done **uncommitted**; agent stalled going off-plan into a UITests target — the untracked `BreathingPreviewUITests.swift` should be discarded (plan never asked for UI tests) |
| `feature/onboarding-survey` | ⬜ Not started (branch cut from bodymap when it completes) |
| `fix/page-titles` | ⬜ Not started (runs last, after all merges) |
| Working tree | Uncommitted `project.pbxproj` change = benign Xcode 26.6 auto-upgrade (LastUpgradeCheck 2660, DEAD_CODE_STRIPPING etc.) — commit as a standalone chore |

## Part B — Remaining feature work (spec + plan already written)

### B1. Body map 3D marking — `docs/superpowers/plans/2026-07-04-2-bodymap-3d-marking.md`
**Spec:** one 3D skin-only body map; Mark mode freezes the user's current rotation and the visible projection becomes the drawing surface; strokes unproject via SceneKit hitTest into an invisible muscle-proxy mesh → ~40 `MuscleGroup`s; marked muscles glow through the skin in 3D (rotation-independent); marks persist as `{group: sensationColor}` with legacy-region migration; all 2D silhouette/region-grid code deleted.
- [x] T1 MuscleNameResolver (`373ae8c`, tests green) — **pending task review**
- [ ] T2 `MuscleMarkStore` (persistence + `bodymap.markedRegions` migration; full test code in plan)
- [ ] T3 `BodyRig` skin-only + invisible muscle proxy + x-ray highlight layer; delete `BodySkeleton.obj`
- [ ] T4 `MarkableBodyView` (`UIViewRepresentable` SCNView; hitTest per stroke point; rotate/zoom gestures; live-ink CAShapeLayer)
- [ ] T5 `BodyMapView` rewrite + delete HumanFigureView / BodyFigureCanvas / Muscle+SkeletonAnatomyCanvas / AnatomyDrawingHelpers / silhouettes / AnnotationStore
- [ ] T6 `docs/BLENDER_MUSCLE_EXPORT.md` guide
- [ ] **YOUR action (Jason):** re-export the Z-Anatomy muscle layer from Blender with per-muscle object names kept (T6 documents the exact steps). Until then marking works via the coarse fallback only.

### B2. Onboarding survey + facts — `docs/superpowers/plans/2026-07-04-3-onboarding-survey.md`
**Spec:** Bend-style flow for new users: 5 survey questions (goal, problem areas, flexibility, frequency, preferred time) interleaved with cited stretching-fact cards; answers → `@AppStorage`, problem areas pre-mark body-map muscles, preferred time pre-fills the reminder hour.
- [ ] T1 `SurveyModel` + facts content (+tests) · [ ] T2 pages + pager wiring (deletes `GoalPickerPage`)

### B3. Breathing circle preview — `docs/superpowers/plans/2026-07-04-4-breathing-preview.md`
**Spec:** tapping the idle circle plays ONE silent demo cycle of the selected pattern, interruptible, no session recorded.
- [x] T1 `BreathPreviewController` + tests (`3649fff` in worktree)
- [ ] T2 BreathingView wiring — recover the uncommitted worktree changes, finish per plan, discard the off-plan `BreathingPreviewUITests.swift`

### B4. Page-title fixes — `docs/superpowers/plans/2026-07-04-5-page-titles.md`
**Spec:** screenshot audit at iPhone SE width; convention = tab roots `.large`, pushed pages `.inline`; shorten colliding titles.
- [ ] T1 audit (23 titles) · [ ] T2 fixes + before/after screenshots

### B5. Integration
- [ ] Final whole-branch review per branch, then merge in order: exercise-library → bodymap → onboarding → breathing-preview → page-titles (titles audited against the merged result)
- [ ] Commit the Xcode-26.6 pbxproj upgrade as `chore:`

---

## Part C — Audit findings (2026-07-05, full-app read-only audit)

### C1. 🚨 Crash paths on real devices (HIGH — fix before any TestFlight)
**Spec:** no permission request may fire without its Info.plist usage string and entitlement.
1. **HealthKit**: `HealthKitService.requestAuthorization()` (Services/HealthKitService.swift:40) auto-fires after every completed session (BreathingView.swift:595, SessionPlayerView.swift:264) but the project has **no `NSHealthShareUsageDescription`/`NSHealthUpdateUsageDescription` and no HealthKit entitlement** → `NSInvalidArgumentException` on first completed session on-device.
   *Plan:* add HealthKit capability + both `INFOPLIST_KEY_NSHealth*UsageDescription` build settings; gate the request behind the Settings toggle (explicit user action) instead of auto-firing post-session.
2. **Calendar**: `requestFullAccessToEvents()` (CalendarService.swift:20) fires from the "Add Sessions to Calendar" toggle with no `NSCalendarsFullAccessUsageDescription`.
   *Plan:* add `INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription`.
3. **CloudKit config mismatch**: `ModelConfiguration(cloudKitDatabase: .automatic)` (App:20) with **no iCloud entitlement**; `BodyPart` model has no inline defaults (Models/BodyPart.swift:12–17) violating CloudKit rules; on failure the app silently falls back to an **in-memory store** (App:31–33) = user sees all data gone, every launch.
   *Plan:* short-term switch to `cloudKitDatabase: .none`; give `BodyPart` inline defaults now (schema-safe); when iCloud actually ships: add entitlement + visible error UI instead of silent in-memory fallback.

### C2. 🚫 App Store rejection risks (HIGH — fix before submission)
**Spec:** paywall and privacy surfaces must satisfy 3.1.2 / 2.3.2 / ITMS-91053.
1. **No `PrivacyInfo.xcprivacy`** anywhere — uploads now fail on required-reason APIs (UserDefaults everywhere). *Plan:* add privacy manifest declaring CA92.1 + collected data types (leaderboard name/stats).
2. **Paywall lacks Terms of Use + Privacy Policy links** (PaywallView.swift:244–256); in-app Privacy Policy is a placeholder with a **false claim** ("private Supabase instance" — it's shared/public) (ProfileSettingsTab.swift:215–222); AuthView's ToS text links nowhere (AuthView.swift:117). *Plan:* host real pages, link from paywall/auth/settings.
3. **Fabricated compare-at prices** ($39.99/$5.99/$89.99 strikethroughs, PaywallView.swift:14–23,106–124) inside a hardcoded 90-day "launch window" from a guessed date (line 20), hardcoded "$" (breaks non-USD), hardcoded "7-Day Free Trial" not read from `product.subscription?.introductoryOffer` (lines 153, 206). *Plan:* derive trial + pricing display from StoreKit; delete invented strikethroughs; tie promos to first-launch date or remote flag.

### C3. 🔓 Backend integrity (HIGH/MED)
**Spec:** strangers must not be able to vandalize or exhume other users' data.
1. Supabase `profiles`/`routines` are **anon-writable** (`with check (true)`, supabase_schema.sql:72–79,123–130) with the publishable key in the binary → anyone can overwrite every leaderboard row. *Plan:* wire the already-written-but-never-called `signInWithApple(identityToken:)` (SupabaseService.swift:130–138) into Supabase Auth and scope write policies to `auth.uid()`; until then, consider read-only leaderboard.
2. `deleteAccount()` never deletes the public `profiles` row (AuthManager.swift:178–190) — orphaned personal data, GDPR/5.1.1(v) exposure. *Plan:* DELETE the row before rotating the anon ID.
3. Dead remote-social endpoints (`uploadRoutine`/`uploadSession`/`fetchPublicRoutines`, zero call sites) keep open write policies alive. *Plan:* delete endpoints + drop unused policies, or finish the feature.

### C4. 🔀 Unmerged fixes — ~24 finished branches ship nowhere (MED, cheap wins)
**Spec:** every already-written fix either merges or is consciously discarded.
*Plan:* triage-merge, then delete stale refs. Highest value: `fix/deadline-based-timers` + `fix/watch-deadline-based-timer` (breathing timers freeze in background — BreathingView.swift:69–73), `fix/signout-clears-userdefaults` (sign-out leaves email on disk), `fix/email-case-sensitivity`, `fix/apple-signin-email-recovery` (stable Apple user ID never persisted), `fix/seed-exercise-stable-uuid` (random seed UUIDs → catalog duplicates once sync exists), `fix/userprofile-dedupe`, `test/core-logic-unit-tests`.

### C5. 🗃️ Data integrity & honesty (MED)
1. Migrations bump `seedDataVersion` even when `context.save()` fails (App:180–183, 269–272) → migration silently skipped forever. *Plan:* bump version only after successful save.
2. Migration matches by exercise **name** — a user rename breaks it. *Plan:* key on stable UUIDs (pairs with `fix/seed-exercise-stable-uuid`).
3. Email "accounts" are device-local keychain illusions (AuthManager.swift:130–159) — no server, no reset. *Plan:* label honestly or back with Supabase Auth (pairs with C3.1).
4. Data export omits profile/badges/routines/annotations (DataExportView.swift:8). *Plan:* export all user-generated data.
5. "2FA" is a biometric launch gate stored as `auth.twoFAEnabled` (AuthManager.swift:38). *Plan:* rename with defaults migration; fix TODO.md claim.

### C6. ⚠️ UX/safety gaps (MED)
1. **Exercise cautions never appear during sessions** — 5+ entry points launch `SessionPlayerView` directly bypassing the detail page's CautionCard (HomeView.swift:53, TodayView.swift:59, ForYouSection.swift:46, ExerciseListView.swift:91, GuidedProgramDetailView.swift:42); 66/152 seed exercises define cautions. *Plan:* render the caution inside SessionPlayerView before/atop each exercise.
2. First Body Map open parses multi-MB OBJs synchronously on the main thread (BodySceneView.swift:161–205) — seconds-long freeze on older devices. *Plan:* background-load templates with a placeholder (fold into bodymap plan T3).
3. Localization 36% complete across 4 declared languages (129/356 keys) — mixed-language UI for es/fr/zh users. *Plan:* finish or unlist the languages.
4. "Female" body-type picker promises a female model that doesn't exist (GenderPickerPage.swift:29–35 vs `BodyMale` only). *Plan:* soften the picker copy now; female mesh later.

### C7. 🧹 Hygiene (LOW)
- Widget/Watch directories are dead code in no target, App Group is `group.REPLACE_WITH_YOUR_BUNDLE_ID` (WidgetDataService.swift:15) — add real targets or delete.
- Empty untracked `Views 2/` + `Resources 2/` folders — `rmdir`.
- `HumanFigureView.swift` (647 lines) zero references — deleted anyway by bodymap T5.
- ~7 MB OBJs — convert to .scn/.usdz (5–10× smaller) after the bodymap rework settles.
- `restorePurchases` swallows failure (`try? await AppStore.sync()`, StoreManager.swift:87–90) — surface an alert.
- All I/O services are untestable singletons (hardwired `UserDefaults.standard`/`URLSession.shared`) — inject seams when next touched.

---

## Suggested order of attack

1. **C1 crash paths** (an afternoon; blocks any device testing)
2. **B1/B3 finish in-flight branches** (bodymap T2–T6, breathing T2) → **B2** → merges → **B4**
3. **C4 branch triage** (cheap, high value) + **C5.1** (one-line guard)
4. **C2 App Store pack** (privacy manifest, paywall links/pricing) before submission
5. **C3 backend hardening** before promoting the leaderboard
6. C5/C6 rest, then C7 as filler
