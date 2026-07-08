# Node-Graph Exercises Tab — Design

Status: approved (user confirmed zoom mechanic, search behavior, and toolbar/banner scope during brainstorming — see decisions below)

## Problem

The Exercises tab (`ExerciseListView`) is a flat, filterable list. The user wants
a more explorable, visually simplistic browsing experience: category "nodes"
(Back, Legs, Shoulders, ...) that the user pinch-zooms into to reveal the
exercises in that category, matching the pinch-to-reveal interaction already
built for Body Map. A search bar equivalent to today's must remain available.

## Scope

In scope: replacing the browsing surface of the Exercises tab (`HomeView`'s
tab index 2) with a zoomable node-graph canvas, plus its search bar and
toolbar.

Out of scope: `BodyPartExercisesView` (the flat filtered list reached from
Body Map's "Find Exercises" banner) is unchanged — it's a different entry
point serving a different job (showing exercises for a specific marked
region, not general browsing).

## Decisions made during brainstorming

1. **Zoom mechanic**: continuous pinch-zoom over a single canvas (like
   `BodyMapView`'s `zoomScale`/`panOffset`/`MagnifyGesture`), not a discrete
   tap-to-drill-in / back-button model. Pinching in near a category reveals
   its exercises; pinching back out returns to the category overview.
2. **Search**: typing in the search bar swaps the canvas for a flat,
   live-filtered list (reusing `ExerciseRow` and the existing
   `localizedCaseInsensitiveContains` filter logic) — functionally identical
   to today's `.searchable` behavior. Clearing the search restores the graph.
3. **Toolbar & banners**: the `+` create-exercise button and the
   Stretch/Breath/Both type filter stay in the toolbar and apply to which
   nodes are visible on the canvas. The `ForYouSection`, sleep-suggestion
   banner, and calendar free-slot banner are dropped — they don't fit a
   full-canvas graph and the user asked for a simpler tab.

## Category taxonomy

All 152 seed exercises' `targetBodyParts` values are `MuscleGroup` raw
values already (verified against `SeedData.json` — no data migration
needed). Eight coarse categories bucket all 39 `MuscleGroup` cases:

| Category | MuscleGroup cases |
|---|---|
| Neck | Front Neck, Back Neck, Head |
| Shoulders | Left/Right Shoulder, Left/Right Trapezius |
| Chest | Left/Right Chest |
| Back | Left/Right Lats, Spinal Erectors, Lower Back |
| Core | Abs, Left/Right Obliques |
| Arms | Left/Right Biceps, Left/Right Triceps, Left/Right Forearm, Left/Right Hand |
| Hips & Glutes | Left/Right Glutes, Left/Right Hip Flexors, Left/Right Adductors |
| Legs | Left/Right Quadriceps, Left/Right Hamstrings, Left/Right Calves, Left/Right Tibialis, Left/Right Foot |

An exercise whose `targetBodyParts` span multiple categories appears as a
node under each (mirrors how `BodyPartExercisesView` already allows
multi-region matches). Every exercise maps to at least one category — no
orphans.

New file `Models/ExerciseCategory.swift`:

```swift
enum ExerciseCategory: String, CaseIterable, Identifiable {
    case neck = "Neck", shoulders = "Shoulders", chest = "Chest", back = "Back",
         core = "Core", arms = "Arms", hipsGlutes = "Hips & Glutes", legs = "Legs"
    var id: String { rawValue }
    var accentColor: Color { ... }        // 8 fixed hues, dark/light aware like LuminaTheme
    static func categories(for targetBodyParts: [String]) -> Set<ExerciseCategory> { ... }
}
```

## Layout & rendering

- 8 category nodes sit in a fixed radial layout (evenly spaced on a ring
  around a center point), sized by their exercise count, each tinted its
  `accentColor`.
- When a category is focused (see below), its exercises render as smaller
  nodes in a ring around the category's position, tinted the same color.
  Exercise node position is deterministic (index around the ring) — no
  physics simulation, so it's calm and reproducible rather than jittery.
- Rendering uses a single `Canvas` (as `BodyFigureCanvas` already does for
  ~25 region rects) to draw all circles + labels, plus a thin transparent
  hit-testing overlay only for the nodes currently interactive (focused
  category's children, or all 8 categories at overview zoom). This avoids
  instantiating 150+ live SwiftUI views and reuses a pattern already proven
  in this codebase for performance.

## Interaction model

State: `zoomScale: CGFloat` (1...4, same bounds as Body Map), `panOffset:
CGSize`, `focusedCategory: ExerciseCategory?`.

- **Overview** (`zoomScale` below `focusThreshold`): all 8 category nodes
  visible and interactive; tapping one sets `focusedCategory` and animates
  `zoomScale`/`panOffset` to center + zoom on it (a tap acts as a shortcut
  into the same state pinching would reach — avoids requiring pixel-perfect
  pinching to "hit" a category).
- **Focused** (`zoomScale` at/above `focusThreshold` AND a category is
  focused, determined as whichever category node is nearest the canvas
  center under the current pan/zoom): that category's exercise nodes
  crossfade in around it; sibling category nodes fade out and are not
  interactive.
- Pinching/panning back below `focusThreshold` clears `focusedCategory`,
  crossfades the exercise nodes out, and fades the sibling categories back
  in — satisfies "zoom out to see where you are, more nodes popping up."
- Tapping an exercise node pushes `ExerciseDetailView` (`NavigationLink`,
  unchanged from today).
- Type filter (Stretch/Breath/Both) hides non-matching exercise nodes and,
  if a category has zero remaining matches, dims/hides that category node
  at overview too.

## Search

A `.searchable(text:)` search bar identical in placement/prompt to today's
(`"Search exercises"`). Non-empty search text replaces the `Canvas` with the
existing flat, live-filtered `LazyVStack` of `ExerciseRow`s (same
`filtered` logic moved over from `ExerciseListView`). Clearing search
restores the canvas at its last zoom/pan state.

## New/changed files

- New: `Models/ExerciseCategory.swift` — category enum + `targetBodyParts`
  → category mapping + accent colors.
- New: `Views/Exercises/ExerciseGraphView.swift` — the canvas, gesture
  handling, focus state, node layout math.
- Rewritten: `Views/Exercises/ExerciseListView.swift` — becomes the tab's
  root: toolbar (create/+, type filter), `.searchable`, and switches between
  `ExerciseGraphView` (no search text) and the flat filtered list (search
  text present). `ExerciseRow` stays as-is and is reused by both the search
  list and (unchanged) `BodyPartExercisesView`.
- Unchanged: `BodyPartExercisesView`, `ExerciseDetailView`,
  `CreateExerciseView`, `ExerciseRow`.

## Testing

- Unit test for `ExerciseCategory.categories(for:)` covering: single-part
  exercise, multi-category exercise, and confirming every `MuscleGroup` case
  maps to exactly one category (exhaustiveness check via `CaseIterable`).
- Manual simulator verification (per `.claude/skills/verify/SKILL.md`):
  screenshot the overview (8 nodes), a focused category (exercise nodes
  visible), and the search-swapped list.
