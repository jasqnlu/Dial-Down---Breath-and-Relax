# Roadmap Carousel + Cross-Tab Exercise Picking — Design

## Context

`CustomizeRoutineView`'s "Add Exercises" flow currently opens `ExercisePickerSheet`
— a small local sheet (search + grid + `MiniRoutineState`) explicitly built to
avoid a tab switch (see its doc comment). Its roadmap preview (`RoadmapWave`)
shows every exercise node at once on a wave curve inside a free-scrolling
`ScrollView`, with no sense of a "current" exercise.

Two changes, requested together and validated against an interactive HTML
mockup before any Swift was touched:

1. **RoadmapWave becomes a zoomed-wave paging carousel.** One exercise
   centered/large per page; neighbors peek and recede; the curve itself
   thickens/brightens near the focused node and dims/blurs toward the edges,
   selling an actual camera zoom into that point on the timeline, not just a
   bigger icon.
2. **"Add Exercises" now sends the user into the real Exercises tab** — the
   existing 8-region node graph (`ExerciseGraphView`) — in a picking mode,
   instead of the disconnected `ExercisePickerSheet`. A bottom bar shows the
   running pick count/time with a "Done" button; picking mode survives tab
   switches; Done returns to Home with the picks merged into Customize.

The mockup itself was reviewed live as a Claude Artifact (not committed to
the repo) — this doc captures the resulting decisions.

## Decisions (validated against the mockup, in order made)

- **Carousel style**: "zoomed wave," not a flat card pager — the cosine
  curve stays, the camera effectively zooms into whichever node is centered.
- **Zoom mechanism**: node scale/opacity falloff by distance from viewport
  center, a per-segment curve (not one flat path) whose stroke-width/opacity/
  blur also falls off by distance, a fixed radial vignette over the
  viewport (doesn't scroll with content) that stays clear at center and
  dims toward the edges, and a soft glow behind the centered node. Node
  transform pivots near its duration label (not dead-center) so scaling up
  grows the glyph *upward* into headroom rather than pushing the label
  toward the container edge — this specifically fixes clipping on nodes
  that sit on the low side of the curve (odd indices, per
  `RoadmapWaveGeometry.y`).
- **Applies to both call sites**: `CustomizeRoutineView`'s numbered roadmap
  *and* `TodayView`'s home-hero roadmap both get the carousel treatment —
  one shared `RoadmapWave` component, one consistent feel. No
  `pagingEnabled` flag to opt one out.
- **"Add Exercises" is a labeled button**, not a bare "+" icon — stays in
  the toolbar (not the scrolling list), preserving the existing fix for the
  overlap bug called out in `CustomizeRoutineView`'s toolbar comment.
- **Add Exercises → real Exercises tab, picking mode.** Confirmed: this
  means the actual 8-region graph (`ExerciseGraphView`), not a simplified
  grid. The region circles (top-level ring, `GraphLayout.categoryPosition`)
  are unchanged — tapping one still zooms/focuses exactly as it does today.
  Picking-mode behavior is scoped to leaf-level exercise taps: the
  satellite ring `ExerciseGroupNode` buttons that currently push
  `ExerciseGroupCorpusSheet`, and the `ExerciseGridTile`s inside that sheet
  (and the search-mode grid in `ExerciseListView`) — a tap there toggles
  selection instead of opening `ExerciseDetailView`.
- **Picking-mode bottom bar**: "N exercises · X min · Done," reflecting
  **only the newly-picked exercises this session**, not combined with the
  routine's pre-existing base list (that combined total is already visible
  once the user lands back in Customize).
- **Picking mode persists across tab switches** — browsing Home/Body
  Map/etc. with picking mode active does not cancel it; only "Done" ends
  it.
- **Done → Home (tab 0), Customize re-presented with picks merged.**
  `CustomizeRoutineView` is only ever presented from `TodayView` (confirmed
  by grep — no other call sites besides tests), so "always return to tab 0"
  is safe to hardcode.
- **`ExercisePickerSheet` and `ExercisePickerCandidates` become dead code**
  once the "+" toolbar action is rewired, and should be deleted (along with
  their now-dead test file) rather than left unused. `MiniRoutineState`
  stays — it's also used by Body Map's mini-routine builder.

## Architecture

### RoadmapWave carousel (`Views/Home/RoadmapWave.swift`)

- Deployment target is iOS 26.5, so modern scroll APIs are available
  without fallback shims: `.onScrollGeometryChange(for:of:action:)` for
  continuous content-offset tracking (needed for per-frame scale/opacity/
  blur, not just settled-position snapping), and a custom
  `ScrollTargetBehavior` that snaps to `RoadmapWaveGeometry.nodeSpacing`
  multiples (not `.paging`, which snaps to container-width multiples — the
  wrong fit here since node spacing is fixed and container width varies).
- Curve rendering changes from one continuous `Path` to one path segment
  per inter-node span, each independently styled (stroke-width/opacity/
  filter) from its midpoint's distance to the viewport center.
- `RoadmapWaveGeometry`'s leading/trailing padding, currently fixed
  constants sized for "node 0 at scroll-start," need to become
  viewport-width-dependent (`visibleWidth/2`-ish) so node 0 and the last
  node can each reach the *center* of the viewport, not just the leading
  edge. This requires a `GeometryReader` around `RoadmapWave` (or reading
  width via the scroll geometry callback). The existing "spacing is fixed,
  never fit-to-width" invariant is about *spacing*, not padding, and stays
  intact — update the doc comment to clarify padding is viewport-dependent
  while spacing remains constant.
- Numbered-badge visibility: fade out below a size/scale threshold so
  peeking (non-focused) nodes don't show illegible tiny numbers.
- `TodayView.swift`'s hero call site and `CustomizeRoutineView.swift`'s
  numbered call site both get the new behavior automatically (shared
  component); no new view-level parameter needed to opt one out.

### Picking-mode state (`Services/ExercisePickingSession.swift`, new)

A small `ObservableObject`, mirroring how `DeepLinkRouter` is already
injected app-wide, but shaped differently: `DeepLinkAction` is a one-shot
`Identifiable` enum driven through `.sheet(item:)`; picking mode is
persistent, mutated by taps arbitrarily deep inside the Exercises tab
across any number of tab switches, so it needs its own environment object
rather than overloading `DeepLinkAction`.

```swift
final class ExercisePickingSession: ObservableObject {
    struct Context {
        let title: String
        let isPinned: Bool
        let baseExercises: [Exercise]
    }

    @Published private(set) var isActive = false
    @Published private(set) var context: Context?
    @Published private(set) var picked: [Exercise] = []

    func begin(context: Context)
    func toggle(_ exercise: Exercise)
    func isPicked(_ exercise: Exercise) -> Bool
    /// Returns (context, merged) and clears session state. `merged` reuses
    /// `CustomizeRoutineExerciseMerge.appending` for the same dedup
    /// behavior as today's Add Exercises flow.
    func finish() -> (context: Context, merged: [Exercise])?
    func cancel()
}
```

Injected via `.environmentObject` at the same site `DeepLinkRouter`/
`AuthManager` already are (app root).

### Wiring

1. `CustomizeRoutineView`'s "Add Exercises" toolbar button:
   `pickingSession.begin(context:)`, `dismiss()`, post the existing
   `.browseExercisesRequested` notification (already used by
   `SessionPlayerView` for the identical "dismiss + switch to Exercises
   tab" need — no new notification required for this leg).
2. `ExerciseListView` / `ExerciseGraphView` / `ExerciseGroupCorpusSheet`
   read `pickingSession.isActive` (via environment object, avoiding a
   parameter-drilling chain through `categoryLayer`) and branch leaf taps:
   picking mode toggles selection (reusing `ExerciseGridTile`'s existing
   `.add(isSelected:)` badge) instead of opening `ExerciseDetailView`.
3. `ExerciseListView` adds a `.safeAreaInset(edge: .bottom)` picking bar
   (guarded by `pickingSession.isActive`), showing count/time computed
   purely from `pickingSession.picked`, with a "Done" action.
4. "Done" calls `pickingSession.finish()`, posts a new
   `.exercisePickingFinished` notification (`Services/AppNotifications.swift`).
5. `HomeView` listens for `.exercisePickingFinished` and sets
   `selectedTab = 0`.
6. `TodayView` also listens for `.exercisePickingFinished`, reads the
   finished `(context, merged)` off the session object, and re-presents
   `CustomizeRoutineView` (`showingCustomize = true`) seeded with `merged`
   and the original `title`/`isPinned`.

### Cleanup

Delete `Views/Home/ExercisePickerSheet.swift`,
`Views/Home/ExercisePickerCandidates.swift`, and
`Breath - Relax & StretchTests/ExercisePickerCandidatesTests.swift` once
their only call site (Customize's old "+" sheet) is removed. Re-grep
immediately before deleting to confirm no other references crept in.
`MiniRoutineState` is untouched — still live for Body Map.

## Testing

- Extend `RoadmapWaveRenderingTests.swift` for the new paging/focus
  rendering (non-crash + sane geometry at a non-zero scroll offset; full
  snap/gesture behavior needs XCUITest, not unit tests).
- New `ExercisePickingSessionTests.swift` (Swift Testing, mirroring
  `MiniRoutineStateTests.swift`) covering `begin`/`toggle`/`finish`
  semantics, especially merge/dedup via `CustomizeRoutineExerciseMerge`.
- XCUITest driving the full cross-tab flow end to end (per the project's
  `verify` skill): tap "Add Exercises" → Exercises tab appears → tap a
  region → tap tiles → switch tabs and back → selection persisted → Done →
  back on Home with Customize re-presented showing the merged list.
