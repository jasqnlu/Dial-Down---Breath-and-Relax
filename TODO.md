# Breath: Relax & Stretch — TODO

Updated 2026-07-10 (rev 5 — full reset; previous list, including all v0.1–v0.8 history and detailed Xcode/Blender how-tos, archived at [docs/archive/TODO-2026-07-06.md](docs/archive/TODO-2026-07-06.md))

## 0 · Snapshot

- SwiftUI + SwiftData wellness app (breathing, stretching, 3D body map). No third-party dependencies; Supabase spoken over raw `URLSession`.
- Branch `feature/lumina-restyle` holds the Lumina design system (`Views/Theme/`), the node-graph Exercises tab, and the skin-only body map. Roughly half the app's screens are restyled; the rest still use ad-hoc system styling.
- Strategic decisions (2026-07-10): **finish the Lumina restyle first**, and commit to **Supabase full sync** for user data (not CloudKit — the iCloud entitlement item from the old list is superseded).

---

## 1 · 🎨 UI — Finish the Lumina restyle (top priority)

Method: reuse the existing tokens and components — `LuminaTheme.swift` (`.luminaCard()`, `LuminaPillButtonStyle`, `LuminaChip`, dynamic color tokens) and `LuminaFonts.swift` (semantic Manrope scale). Reminder: `.floatingTabBarClearance()` must be applied **inside** each page's `NavigationStack` (documented gotcha in `HomeView`/`CustomTabBar`).

**Tier 1 — highest-traffic screens:** ✅ done 2026-07-10 (142 unit tests green, simulator-verified light+dark via `LuminaRestyleScreenshotTests`)
- [x] `Views/Session/SessionPlayerView.swift`
- [x] Auth flow: `Views/Auth/AuthView.swift`, `EmailAuthView.swift`, `AppLockView.swift`
- [x] Onboarding: `Views/Onboarding/` (all pages + `AppGuideView`)
- [x] `Views/Monetization/PaywallView.swift`

**Tier 2:** ✅ done 2026-07-12 (parallel-agent restyle, build+test verified)
- [x] Profile sub-screens: `ProgressChartsView`, `BadgesView`, `LeaderboardView`, `FlexibilityCheckInView`, `DataExportView`
- [x] Routine flows: `RoutineBuilderView`, `ImportRoutineView`, `BorrowRoutineView`, `ChallengeInviteView`

**Tier 3:** ✅ done 2026-07-12
- [x] `Views/Exercises/CreateExerciseView.swift`, `ForYouSection.swift`
- [x] `Views/Monetization/ContentPacksView.swift`, `GuidedProgramDetailView.swift`
- [x] `Views/Legal/LegalDocumentView.swift`

---

## 2 · 🎨 UI — Cross-cutting polish

- [x] **One corner-radius token** — done 2026-07-12: `LuminaRadius` (card/panel/control/chip/badge/tag) added to `LuminaTheme.swift`, magic-number call sites swept across Home/Auth/Breathing/Profile/Exercises/Monetization/Onboarding/BodyMap
- [x] **Dynamic Type pass** — done 2026-07-12: `CustomTabBar`/`ProfileView` tab icons and `SessionPlayerView` countdowns now use `@ScaledMetric`; `ExerciseGraphView`/`BodyFigureCanvas` pinned to `.large` where growth would overflow fixed canvas math. Follow-up noted, not fixed: `BreathingView`'s countdown and `BorrowRoutineView`'s badge need a layout rework, not just a font tweak
- [x] **Reduce-motion parity** — done 2026-07-12: `BreathingView`'s phase animation and `ExerciseGraphView`'s pinch-zoom/focus springs now honor `accessibilityReduceMotion`, matching `TodayView`'s existing pattern
- [x] **Wire AuthView Terms/Privacy links** — done 2026-07-10: underlined Terms of Use / Privacy Policy buttons present `LegalDocumentView` sheets
- [x] **Page-title audit + fixes** — done 2026-07-12: fixed truncation on Body Map's marking title ("Mark Your Body" → "Mark Areas") and Data Export ("Export My Data" → "Export Data"); aligned Breathing/Routines to the `.inline` display mode every other tab root uses (plan: [docs/superpowers/plans/2026-07-04-5-page-titles.md](docs/superpowers/plans/2026-07-04-5-page-titles.md))

---

## 3 · 🔌 Infrastructure — Supabase full sync (committed direction)

Today "offline-first" only covers the seed catalog (pull-only refresh). Sessions, routines, and profile edits never leave the device — the write paths were deleted as dead code. Build order matters:

1. [ ] **Provision the backend** (Jason) — run [supabase_schema.sql](supabase_schema.sql) in the SQL editor; enable the Apple auth provider (details in archived TODO ⚙️)
2. [ ] **Test seam first** — `URLProtocol`-based mock for `SupabaseService` (the HTTP layer has zero tests); write it before touching sync logic
3. [ ] **Auth unification** — only Apple sign-in yields a Supabase session; email/password is local PBKDF2 and Google/guest never touch the backend, so their writes are RLS-rejected. Evaluate Supabase email auth and/or anonymous sessions so every user has a backend identity
4. [ ] **Restore write paths** — re-add session/routine upload to `Services/SupabaseService.swift` and re-add the matching RLS insert/update policies to `supabase_schema.sql` (both dropped when writes were dead code)
5. [ ] **Sync engine** — SwiftData-persisted outbox of pending ops; push on foreground/connectivity; pull-merge by `uuid`; last-write-wins conflict policy to start
6. [ ] **Fix stale DTO comment** — `SupabaseDTOs.swift:50` says `RemoteProfile.id` is the auth email, but code keys it on the anonymous UUID

---

## 4 · 🧱 Infrastructure — Foundation hardening

- [x] **UUID-keyed seed migrations** — done 2026-07-12: `Exercise.seedID` added, seed migrations now key on it (v4 matches by seedID first, falling back to name only for pre-existing rows; v6 backfills seedID for legacy installs); matching/migration logic extracted to testable `SeedMigrator`, 7 new tests against an in-memory `ModelContext`
- [x] **Background-load the OBJ models** — done 2026-07-12: OBJ parse/triangulation moved to a `BodyMeshLoader` actor, `BodySceneView` shows a loading placeholder until the mesh attaches. `.usdz`/`.scn` bundle-size conversion still open, deliberately deferred
- [x] **Surface the in-memory `ModelContainer` fallback** — done 2026-07-12: one-time alert shown on launch when the fallback path was taken
- [x] **Reconcile build settings** — checked 2026-07-12: bumping `SWIFT_VERSION` to 6.0 fails immediately on an existing `@MainActor`-isolation violation, confirmed real concurrency work is needed (not a flip) — left at 5.0. `IPHONEOS_DEPLOYMENT_TARGET = 26.5` matches the installed toolchain's actual SDK, not a typo — left as-is
- [x] **Committed Supabase anon key** (`SupabaseService.swift`) — decided 2026-07-12: acceptable as-is (RLS is the real boundary); decision recorded as a comment above the key so it isn't reopened

---

## 5 · 📦 Carried-over open items

**In-flight work:**
- [ ] **Finish breathing preview (Task 2)** — half-done wiring sits in worktree `.claude/worktrees/agent-ac2c9b9e789ee75c0`; plan: [docs/superpowers/plans/2026-07-04-4-breathing-preview.md](docs/superpowers/plans/2026-07-04-4-breathing-preview.md)
- [ ] **Onboarding survey + facts (reconciled)** — the original plan ([docs/superpowers/plans/2026-07-04-3-onboarding-survey.md](docs/superpowers/plans/2026-07-04-3-onboarding-survey.md)) is **stale**: it pre-marks via `MuscleMarkStore` (removed with the 3-layer body map — marks now persist to the `bodymap.markedRegions` UserDefaults key) and says "delete `GoalPickerPage.swift`", but that file now also holds the new `FocusAreaPickerPage` (added 2026-07-12). Reconciled scope: **keep** the focus-area page as the "problem areas" capture (feed the chosen `ExerciseCategory`s → coarse region names → `bodymap.markedRegions` for pre-marking), and **add** the net-new parts — flexibility/frequency/preferred-time questions, ≥5 cited fact cards, and preferred-time→`NotificationsPage` reminder-hour. Build `SurveyModel` + tests first (Task 1 is conflict-free).
- [ ] **Branch triage** — analyzed 2026-07-12 via `git cherry feature/lumina-restyle <branch>`. **Safe to delete (all commits already re-implemented on the branch):** `feature/exercise-video-tutorials` (−8), `feature/expanded-exercise-library-with-videos` (−9), `test/core-logic-unit-tests` (−9), and `fix/seed-exercise-stable-uuid` (superseded by `Exercise.seedID`, §4). **Keep/evaluate (unique patch not on branch — mostly single-commit fixes):** the remaining ~17 `fix/*` + `test/*` branches, plus `feature/breathing-preview` (§5 in-flight), `worktree-bodymap-3d-anatomy` (+4), `worktree-plan-checkoff-exercise-library`, `docs/update-todo-post-audit`. Note: "+1 unique" means the patch isn't identical — a few may already be re-implemented differently, so verify each small fix against current code before merging vs deleting. (deletes/merges left for Jason to run.)
- [ ] **Live Activity / Dynamic Island** for active sessions — needs the Widget extension target to exist first

**Compliance (before TestFlight):**
- [ ] **Localization decision** — ~36% coverage across es/fr/zh-Hans gives mixed-language UI; finish coverage (+ native-speaker pass) or remove the languages from `knownRegions`
- [ ] **Placeholder IDs still in tree** — `group.REPLACE_WITH_YOUR_BUNDLE_ID` (`WidgetDataService.swift:15` + widget/watch files), Google Client ID (inert until those features go live)

**Jason-only (capabilities, accounts, content — step-by-step guides in the archived TODO):**
- [ ] Xcode: Widget extension target + App Group, `breath://` URL scheme, Watch app + complication targets, StoreKit Configuration scheme step. *(iCloud/CloudKit entitlement no longer needed — superseded by the Supabase sync decision.)*
- [ ] Supabase dashboard: schema + Apple provider (same as §3.1)
- [ ] Blender: per-muscle hitbox re-export ([docs/BLENDER_MUSCLE_EXPORT.md](docs/BLENDER_MUSCLE_EXPORT.md)); female body mesh (unblocks the honest body-type picker)
- [ ] Content: film exercise demo videos, hosted Terms/Privacy URLs, native-speaker localization pass
- [ ] App Store Connect: create the three **consumable** tip products (`tip_small`, `tip_medium`, `tip_large`) — IDs must match `StoreManager.ProductID`. The paid tier was removed 2026-08-09; everything is free and tips unlock nothing

**Done since the old list (recorded so nothing looks dropped):**
- [x] Body-map 3-layer removal — landed on `feature/lumina-restyle` (skin-only map, muscle proxy hit-testing)
- [x] Legal documents bundled (`LegalDocumentView`) — AuthView linking still open (§2)
- [x] `isBilateral` seeding/migration (v5) + side-switch cues in the session player

---

## 6 · 🌫 Deferred (deliberate)

- Mac Catalyst / visionOS — after the iPhone app is solid
- Exercise-instruction localization (152 exercises × 3 languages) — much larger than the UI-string catalog
- `BorrowRoutineView` placeholder URL — resolves itself once Supabase is provisioned

---

## 🗓 Sprint order

| Sprint | Focus |
|--------|-------|
| A | Lumina Tier 1 + cross-cutting polish (§1 T1, §2) |
| B | Lumina Tiers 2–3 + page titles |
| C | Supabase sync: test seam → auth unification → write paths → outbox (§3) |
| D | Foundation hardening + branch triage (§4, §5) |
| E | Capabilities, compliance, TestFlight prep |
