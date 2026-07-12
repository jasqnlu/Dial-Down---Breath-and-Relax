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

**Tier 2:**
- [ ] Profile sub-screens: `ProgressChartsView`, `BadgesView`, `LeaderboardView`, `FlexibilityCheckInView`, `DataExportView`
- [ ] Routine flows: `RoutineBuilderView`, `ImportRoutineView`, `BorrowRoutineView`, `ChallengeInviteView`

**Tier 3:**
- [ ] `Views/Exercises/CreateExerciseView.swift`, `ForYouSection.swift`
- [ ] `Views/Monetization/ContentPacksView.swift`, `GuidedProgramDetailView.swift`
- [ ] `Views/Legal/LegalDocumentView.swift`

---

## 2 · 🎨 UI — Cross-cutting polish

- [ ] **One corner-radius token** — buttons mix `Capsule` and `RoundedRectangle(14)` across Breathing/Paywall/Onboarding; add the token to `LuminaTheme` and sweep (carried from old §4D)
- [ ] **Dynamic Type pass** — Lumina fonts scale via `relativeTo:`, but only `ExerciseGraphView` uses `ScaledMetric`/`dynamicTypeSize`; audit fixed-size text (12pt tab labels, graph node text) at accessibility sizes
- [ ] **Reduce-motion parity** — honored in `TodayView` only; audit `BreathingView`'s animation and the graph pinch-zoom
- [x] **Wire AuthView Terms/Privacy links** — done 2026-07-10: underlined Terms of Use / Privacy Policy buttons present `LegalDocumentView` sheets
- [ ] **Page-title audit + fixes** — screenshot audit at iPhone SE width, then convention/truncation fixes (carried; plan: [docs/superpowers/plans/2026-07-04-5-page-titles.md](docs/superpowers/plans/2026-07-04-5-page-titles.md))

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

- [ ] **UUID-keyed seed migrations** — `migrateSeedToV3/V4/V5IfNeeded` match rows by exercise *name* (renames break migration forever); key on stable UUIDs (`fix/seed-exercise-stable-uuid` branch exists) and add tests against an in-memory `ModelContext`
- [ ] **Background-load the OBJ models** — first Body Map open parses ~7 MB of OBJs synchronously on the main thread; load off-main with a placeholder. Later: convert to `.usdz`/`.scn` (5–10× smaller bundle)
- [ ] **Surface the in-memory `ModelContainer` fallback** — on store-open failure the app silently loses persistence for the session (`Breath__Relax___StretchApp.swift`); tell the user
- [ ] **Reconcile build settings** — `SWIFT_VERSION = 5.0` vs. code written to Swift 6 concurrency rules; and decide whether `IPHONEOS_DEPLOYMENT_TARGET = 26.5` is intentional (very aggressive floor)
- [ ] **Committed Supabase anon key** (`SupabaseService.swift:18-19`) — decide: acceptable (anon keys are semi-public by design, RLS is the real boundary) or move to a config file

---

## 5 · 📦 Carried-over open items

**In-flight work:**
- [ ] **Finish breathing preview (Task 2)** — half-done wiring sits in worktree `.claude/worktrees/agent-ac2c9b9e789ee75c0`; plan: [docs/superpowers/plans/2026-07-04-4-breathing-preview.md](docs/superpowers/plans/2026-07-04-4-breathing-preview.md)
- [ ] **Onboarding survey + facts** — now unblocked (body-map work landed); plan: [docs/superpowers/plans/2026-07-04-3-onboarding-survey.md](docs/superpowers/plans/2026-07-04-3-onboarding-survey.md)
- [ ] **Branch triage** — ~24 unmerged fix/test branches; delete re-implemented ones, rebase-merge keepers (candidate list in archived TODO §1)
- [ ] **Live Activity / Dynamic Island** for active sessions — needs the Widget extension target to exist first

**Compliance (before TestFlight):**
- [ ] **Localization decision** — ~36% coverage across es/fr/zh-Hans gives mixed-language UI; finish coverage (+ native-speaker pass) or remove the languages from `knownRegions`
- [ ] **Placeholder IDs still in tree** — `group.REPLACE_WITH_YOUR_BUNDLE_ID` (`WidgetDataService.swift:15` + widget/watch files), Google Client ID (inert until those features go live)

**Jason-only (capabilities, accounts, content — step-by-step guides in the archived TODO):**
- [ ] Xcode: Widget extension target + App Group, `breath://` URL scheme, Watch app + complication targets, StoreKit Configuration scheme step. *(iCloud/CloudKit entitlement no longer needed — superseded by the Supabase sync decision.)*
- [ ] Supabase dashboard: schema + Apple provider (same as §3.1)
- [ ] Blender: per-muscle hitbox re-export ([docs/BLENDER_MUSCLE_EXPORT.md](docs/BLENDER_MUSCLE_EXPORT.md)); female body mesh (unblocks the honest body-type picker)
- [ ] Content: film exercise demo videos, set real IAP pricing in `Configuration.storekit`, hosted Terms/Privacy URLs, native-speaker localization pass

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
