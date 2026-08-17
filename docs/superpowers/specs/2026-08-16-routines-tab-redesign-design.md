# Routines Tab Redesign — Design Spec

**Date:** 2026-08-16
**Source:** brainstorming session on branch `feature/home-exercises-redesign`; mockup at `docs/superpowers/specs/assets/2026-08-16-today-tab-mockup.html` (also published as a Claude artifact during design).
**Decisions (user-approved):**
- One universal "Today" pin, replacing the Wake-Up-only pin.
- Content Packs deleted; Guided Programs' multi-day structure deleted; both replaced by a single curated `PremadeRoutine` list.
- Public/community routines (publish, browse, borrow) deleted outright — not scaled back.
- Duration editing is a **per-routine override**, not a global catalog edit.
- Premade routines are not their own screen or a separate "add" action — tapping one opens `RoutineBuilderView` itself, pre-seeded, exactly like every other path into that screen.

## Why

Six requests came in together, all touching the Routines tab and Home: generalize the Wake-Up pin into a "Today" routine; replace Content Packs with premade routine templates and surface them on Home; drop the community-routine feature (too much moderation burden for an open-source app to carry); make `RoutineBuilderView`'s "Add Exercise" use the same cross-tab picking flow Customize already has; and let a routine's exercises have their own per-routine durations, adjustable in 5s steps. They're independent enough to ship as separate PRs, but touch enough shared surface (`RoutineBuilderView`, `TodayView`, the `Routine` model) that planning them together avoids rework.

## Data model changes

### `Routine` (existing SwiftData model)

- **Remove:** `isPublic`, `borrowCount`, `authorID`, `authorName`. These exist only to support the community-routine feature being deleted.
- **Keep:** `borrowedFromID` — unrelated to the public library; it marks a routine imported via the private share link (`RoutineSharePayload`/`ImportRoutineView`), which stays.
- **Add:** `var exerciseDurationOverrides: [UUID: Int] = [:]` — exercise UUID → seconds. Absent key means "use `Exercise.durationSeconds`." A plain `[UUID: Int]` is Codable and persists the same way `exerciseIDs: [UUID]` already does; no new `@Model` type needed.
- Requires one schema migration (additive fields + two removed fields), same category of change as the existing `migrateV7` step.

### `PremadeRoutine` (new, replaces `ContentPack` and `GuidedProgram`/`ProgramDay`)

```swift
struct PremadeRoutine: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let exerciseNames: [String]   // resolved against the live Exercise table at render time
}
```

This is `ContentPack`'s existing shape, renamed. `GuidedProgram`, `ProgramDay`, `GuidedProgram.fullReset`, and `GuidedProgram.starterProgram(goalIDs:)` are deleted — the multi-day calendar structure and the onboarding-goal-personalized starter program both go away. Personalization is already covered by Home's existing "Recommended for You" and "For You" sections; duplicating it as a third mechanism isn't worth the upkeep.

Starting set (renames existing packs to match the requested naming, adds one net-new):

| id | title | source |
|---|---|---|
| `pack_deskworker` | Office Stretch | was "Desk Worker Pack" |
| `pack_athlete_recovery` | Athletic Recovery | was "Athlete Recovery Pack" |
| `pack_bettersleep` | Better Sleep & Breathing | unchanged |
| `pack_runner` | Runner's Warm-Up & Cooldown | unchanged |
| `premade_full_body_reset` | Full Body Reset | **new** — no theme, a balanced sweep across flexibility/breathing/posture |

IDs are kept from `ContentPack` where they carry over, so nothing referencing them by string breaks.

## Screen-by-screen

### TodayView — hero + pin

- `sessionExercises` currently checks the pinned routine only inside the `.wakeUp` branch. It now checks a single pinned-routine lookup **before** the time-of-day switch, so a pin applies regardless of wake/unwind/midday.
- `pinnedWakeUpRoutineIDString` (`AppStorage`) → `pinnedTodayRoutineIDString`. On first read after upgrade, if the new key is empty and the old key isn't, migrate the value across once (read old key, write new key, leave old key alone — cheaper than deleting it and there's no harm in an orphaned unused key).
- The saved routine's `name` is always the literal string **"Today"**, not `timeOfDayFocus.heroTitle`. `CustomizeRoutineView`'s toggle row label becomes fixed: "Keep as my Today routine" (was `"Keep as my \(title) routine"`).
- Hero card: when a pin is active, show a small tag next to the title — "🔖 Pinned as Today" — so the state is visible without opening Customize. This needs a new computed property on `TodayView`, e.g. `isPinnedActive: Bool`, since nothing today distinguishes "showing goal-based recommendations" from "showing the pinned routine."
- The pinned "Today" routine is a normal `Routine` row — no special-casing needed in `RoutineListView`.

### PremadeRoutinesView (new, replaces `GuidedProgramsView` + `ContentPacksView` + `GuidedProgramDetailView`)

- A card grid (or list — implementer's call, matches whatever `RoutineListView`'s existing row density suggests) over `PremadeRoutine.all`.
- Tapping a card resolves `exerciseNames` → `Exercise.uuid`s and opens `RoutineBuilderView(initialExerciseIDs: resolvedIDs)` with the routine's `title` used to pre-fill the name field — **not** a bespoke detail/preview screen. This reuses the exact `initialExerciseIDs`/`RoutineIDMerge` seeding path `MiniRoutineReviewView` already uses for picking-session results, so `RoutineBuilderView` needs no new parameter, just a new call site.
- Nothing is persisted by tapping a card. The routine only exists once the user hits Save on the (pre-filled) builder — same as any other entry into that screen.
- `RoutineListView`'s top entry row list collapses from two rows ("Guided Programs", "Content Packs") to one ("Premade Routines").

### Home (`TodayView`) — new section

- New `premadeRoutinesSection`, placed **below "Recommended for You," above "For You."** Recommended is personalized/dynamic and belongs right after the hero; premade routines are evergreen discovery content, a reasonable second stop before the exercise-level "For You" cards.
- Compact tap-through cards (icon circle + title + "N exercises · M min" caption) — no inline "Add" action on the card itself, consistent with PremadeRoutinesView's own cards. Tapping either one opens the same pre-filled `RoutineBuilderView`.
- Card duration/count is computed the same way `TodayView.heroCard` already computes its own "N exercises · M min" line — reuse that logic rather than writing a second copy.

### Remove: public/community routines

Delete outright, no scaled-down version kept:
- `RoutineBuilderView`: the `isPublic` toggle, `myPublicCount`/`publishLimitReached`/`maxPublicRoutines` logic, the "Publish to Community" section.
- `BorrowRoutineView` (whole file).
- `RoutineListView`: the "Browse" toolbar button and its `SupabaseService.isConfigured` guard; the "Public" and borrow-count `Label`s in `RoutineRow`.
- `SupabaseService`/`SupabaseDTOs.swift`: the publish/fetch-public-routines/borrow endpoints and DTOs.
- `DataExportView`: drop the `isPublic`/author columns from the routine CSV export.

**Kept, deliberately:** the private `ShareLink` row action and `RoutineSharePayload`/`ImportRoutineView`. That's a direct link encoding `name` + `exerciseNames`, decoded on import — peer-to-peer, no public listing, no moderation surface, and it doesn't reference any of the fields being removed. "Remove public routine" means removing the open community library, not the ability to hand a friend a link.

### RoutineBuilderView — "Add Exercise" rewiring

Today: opens a local `ExercisePickerView` sheet (defined in the same file). New: routes through `ExercisePickingSession`, matching `CustomizeRoutineView`'s existing "Add Exercises" button — tap it, `pickingSession.begin(context:)`, dismiss, post `.browseExercisesRequested` to switch to the Exercises tab.

This surfaces a real conflict in existing code: `HomeView`'s `.onReceive(.exercisePickingFinished)` hardcodes `selectedTab = 0`, which is correct when Customize (tab 0) started the picking session but wrong when RoutineBuilder (tab 4, Routines) started it — finishing a pick from RoutineBuilder would currently strand the user on the Today tab with the sheet gone.

Fix:
- `ExercisePickingSession.Context` gets a new field, `originTab: Int`.
- `HomeView.onReceive(.exercisePickingFinished)` switches to `context.originTab` instead of the literal `0`.
- `RoutineListView` — the presenter of `RoutineBuilderView`'s sheet — gets its own `onReceive(.exercisePickingFinished)`, mirroring `TodayView`'s existing `customizeOverride` dance: consume the finished pick, hold the merged exercise IDs in local state, and re-present `RoutineBuilderView(routineToEdit:initialExerciseIDs:)` seeded with them via the existing `RoutineIDMerge` helper. No changes needed inside `RoutineBuilderView` beyond swapping what its own "Add Exercise" button does — the re-presentation is the presenter's job, same division of responsibility `TodayView`/`CustomizeRoutineView` already use.
- `ExercisePickerView` (the local sheet struct in `RoutineBuilderView.swift`) is deleted once nothing calls it.

### RoutineBuilderView — per-exercise duration stepper

- Each row in the "Exercises" section gets a `−` / duration / `+` stepper next to the existing remove button, 5-second increments, floored at 5s.
- Backed by `@State private var durationOverrides: [UUID: Int]`, seeded from `routineToEdit?.exerciseDurationOverrides ?? [:]` on appear (and from nothing/empty when creating new — including when pre-seeded from a `PremadeRoutine`, since a preset's exercises use their catalog defaults until the user changes them).
- `saveRoutine()` writes `durationOverrides` into `routine.exerciseDurationOverrides`.
- Displayed/edited value for a row is `durationOverrides[exercise.uuid] ?? exercise.durationSeconds`.

### SessionPlayerView — threading overrides into playback

`SessionPlayerView` reads `exercise.durationSeconds` directly at ~7 call sites (progress totals, current-duration lookups, gamification scoring), each already composed with a global `durationMultiplier` via `scaledDuration(base:multiplier:)`. Add:

- `var durationOverrides: [UUID: Int] = [:]` init param.
- One helper, `effectiveDuration(for exercise: Exercise) -> Int { durationOverrides[exercise.uuid] ?? exercise.durationSeconds }`.
- Swap the ~7 `exercise.durationSeconds` reads for `effectiveDuration(for: exercise)`, still fed through `scaledDuration(base:multiplier:)` unchanged.

`RoutineListView` passes `routine.exerciseDurationOverrides` when presenting `SessionPlayerView` for a saved routine's play button. This is the exact plumbing `CustomizeRoutineView`'s doc comment already flagged as "a real feature that hasn't been built yet" — scoping it to RoutineBuilder-owned routines (not Customize's ad-hoc today-session) keeps this change bounded. Customize adopting the same overrides later is a natural follow-up, not required here — see Out of scope below.

## Sequencing

Four phases, each independently shippable:

1. **Cleanup** — delete public/community routines and Content Packs/multi-day Guided Programs. Pure deletion, lowest risk, unblocks the `Routine` schema migration the other phases build on.
2. **"Today" pin generalization** — `TodayView`/`CustomizeRoutineView`/AppStorage key rename.
3. **Premade Routines** — new `PremadeRoutinesView`, `PremadeRoutine` model, Home section, `RoutineBuilderView` pre-seed call site.
4. **RoutineBuilder rewiring + duration overrides** — cross-tab "Add Exercise," the `originTab` fix, and the duration stepper + `SessionPlayerView` threading, done together since both touch `RoutineBuilderView`'s exercise row and the picking-session plumbing.

## Open questions (flag before/while implementing)

- **Migration for existing pinned Wake-Up routines:** confirmed approach above (copy old AppStorage key to new one, leave old key orphaned) — flagging here only because it's easy to skip by accident and would silently drop existing users' pins.
- **`PremadeRoutinesView` layout (grid vs. list):** left to the implementer; match whatever density `RoutineListView`'s row style already establishes rather than inventing a third pattern.
- **Duration-override floor of 5s:** arbitrary but matches the 5s step size; revisit only if a real exercise's base duration is already under 10s (none currently are, per `SeedData.json`).

## Explicitly out of scope

- Threading `exerciseDurationOverrides` into `CustomizeRoutineView`'s ad-hoc today-session (only `RoutineBuilderView`-owned routines get overrides for now).
- Any UI for browsing other users' routines, even read-only — the whole community layer is gone, not paused.
- Adding more than the five premade routines listed above — five satisfies "multiple," more can be added later without further design work since `PremadeRoutine.all` is just a static array.
- Widget/complication surfaces reflecting the "Today" pin — out of this spec's scope, Home-tab only.
