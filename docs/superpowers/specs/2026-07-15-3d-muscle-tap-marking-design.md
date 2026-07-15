# 3D muscle-tap marking (replaces 2D region overlay + freehand drawing)

## Problem

The body map's tap/marking system lives entirely in a flat 2D overlay
(`BodyRegion` — `Views/BodyMap/HumanFigureView.swift`) composited on top of
the rotating 3D skin render (`BodySceneView.swift`). Two consequences:

- The ~50 `BodyRegion` rects are hand-eyeballed normalized `CGRect`s, tuned by
  looking at the render and nudging numbers until they lined up. They're only
  valid at the two calibrated camera angles (front/back), which is why
  marking mode locks rotation (`BodySceneView.swift:134-137`,
  `interactive: false`).
- Marking also supports freehand drawing: a brush/eraser lets users paint
  "sensation" ink strokes on the body, and the app derives which regions the
  strokes crossed (`BodyFigureCanvas.swift`, `AnnotationStroke`,
  `AnnotationStore`). This machinery — live-draw canvas, saved ink layer,
  eraser blend mode, stroke-to-region derivation — exists to solve a problem
  (attributing screen taps to body parts) that real 3D hit-testing solves
  more simply.

We now have real per-muscle 3D bounding-box data, extracted from the
Z-Anatomy Blender source and unioned into the app's 40 `MuscleGroup`
categories (`Tools/blender/musclegroup_hitboxes.json` — see
`Tools/blender/extract_hitboxes.py` and `classify_hitboxes.py` for the
pipeline, including a corrected left/right convention, a fixed
whole-body recentering pivot, and disambiguated cross-region muscle names).

## Decisions made

- **Replace both interactions** (tap-to-mark and freehand-derived marking)
  with a single tap-based flow. Freehand drawing is removed entirely.
- **Tap cycles sensation type.** The user picks a sensation (existing
  `SensationColor` palette) first, then taps muscles to mark them with that
  sensation; tapping a marked muscle again unmarks it.
- **Old ink/drawing code is deleted**, not left dormant: `AnnotationStroke`,
  `AnnotationStore`, the live-draw `Canvas`, brush/eraser tool UI, and the
  saved-ink rendering layer in `BodyFigureCanvas.swift`.
- **Marking unlocks free rotation.** Since hit-testing works at any camera
  angle (SceneKit's `hitTest` naturally resolves to the nearest/front-facing
  surface along the ray, so occlusion is handled for free on a closed mesh),
  there's no need to lock rotation to front/back during marking anymore.
- **Joints get ~8-10 hand-placed hit volumes** (elbows, knees, wrists,
  ankles, L/R) alongside the 40 muscle groups, since "my knee hurts" is a
  real use case the Blender muscle data doesn't cover on its own.
- **Finger/toe-level marking is dropped.** Marking granularity becomes
  hand/foot as a whole, matching the rest of the redesign (muscle groups,
  not individual muscles or digits).

## Architecture

### Data layer

- `musclegroup_hitboxes.json` (already generated, corrected, and committed
  to `Tools/blender/`) — 40 entries keyed by `MuscleGroup` raw value, each a
  `{min: [x,y,z], max: [x,y,z]}` axis-aligned box in the same normalized
  model space `BodyMeshLoader` centers/scales the skin mesh into
  (`BodySceneView.swift:79-89`: pivot = whole-body bbox center, scale =
  2.0/height).
- A new small hand-authored `joint_hitboxes.json` (~10 entries: elbow, knee,
  wrist, ankle × L/R) in the same coordinate space and format. Positions can
  be derived by inspecting adjacency with the neighboring muscle boxes
  already in `musclegroup_hitboxes.json` (e.g. elbow sits between the
  biceps/triceps boxes' lower y-bound and the forearm box's upper y-bound),
  then verified visually in the simulator.
- Both files get bundled as app resources (same pattern as
  `SeedData.json`).

### Hit-volume nodes (`BodySceneView.swift` / `BodyRig`)

- On body-mesh load, `BodyRig` also loads both hitbox JSON files and builds
  one hidden `SCNNode` per entry: `SCNBox` geometry sized to the box extents,
  positioned at the box center, `node.name` = the `MuscleGroup` raw value (or
  joint identifier), `node.isHidden = true`, added as a child of `bodyNode`.
  Because geometry is parented under `bodyNode`, it inherits the same
  recenter/scale transform as the skin mesh and the rig's Y-rotation for
  free — no separate transform bookkeeping needed.
- Marked nodes toggle from fully hidden to a translucent fill in the current
  sensation's color (this becomes the visual "highlight" replacing today's
  2D rect overlay highlight) — still hit-testable either way via
  `SCNHitTestOption.ignoreHiddenNodes: false`.

### Hit-testing (tap + drag)

- `BodySceneView`'s existing `DragGesture`/tap handling converts a screen
  point to a hit-test against the underlying `SCNView` with
  `[.ignoreHiddenNodes: false]`, returning the tapped node's `name`.
- SwiftUI's `SceneView` doesn't expose the underlying `SCNView` for
  `hitTest` directly, so this needs a thin `UIViewRepresentable` wrapper (or
  switch `BodySceneView` to host an `SCNView` directly) to get a hit-test
  handle — this is an implementation detail to work out in the plan, not a
  design blocker.

### Marking data model

- Replace `AnnotationStore`/`AnnotationStroke` with a much simpler model:
  a dictionary (or small `SwiftData` model) mapping region identifier
  (`MuscleGroup` raw value or joint identifier) → `SensationColor`, persisted
  per facing-independent (a muscle is the same muscle whether you're looking
  at it from the front or back — this is actually a correctness improvement
  over today, where the same physical region could theoretically be marked
  differently on the front-view vs back-view rect since they're
  independently-defined `BodyRegion` sets).
- Downstream consumers (the "Find Exercises" flow) currently read
  `markedRegions: Set<String>`. Muscle identifiers already match
  `Exercise.targetBodyParts` strings (both are `MuscleGroup` raw values), so
  this is a simplification, not a new translation layer — joints (elbow,
  knee, etc.) will need the same fallback treatment `MuscleGroup`'s
  `fallbacks` set already gives head/hands/feet (no `>=3 stretches`
  requirement, and exercises should target the adjacent muscle groups
  instead of a joint name that doesn't appear in seed data).

### Removed

- `BodyAnnotationOverlay.swift`'s drawing-tool UI (brush/eraser picker,
  sensation-for-drawing color picker if distinct from the new tap-first
  picker).
- `AnnotationStroke`, `AnnotationStore`, and the live-draw + saved-ink
  `Canvas` layers in `BodyFigureCanvas.swift`.
- `BodyRegion`, `frontRegions`, `backRegions`, and the hand/foot
  finger/toe-level region constants in `HumanFigureView.swift`.
- The rotation lock during marking (`interactive: false` path tied to
  marking mode) in `BodySceneView.swift`.

## Testing

- A regression test asserting every `Left *` box in `musclegroup_hitboxes.json`
  sits on the negative-x (screen-left) side and every `Right *` box on
  positive-x — this exact convention was inverted once already during
  extraction and silently would have shipped backwards if not caught.
- Pure-geometry unit tests for hit-volume box construction and the
  screen-point → node-name resolution logic (no simulator needed for the
  geometry math itself).
- Manual simulator verification (per the `verify` skill) that tapping a
  visually-obvious muscle (e.g. right bicep) marks the correct
  `MuscleGroup`, at multiple rotation angles, front and back.

## Out of scope for this pass

- Re-exporting the Blender model to carry real per-muscle mesh geometry
  (this design uses simplified box proxies, built from already-extracted
  bounding-box data, added as invisible SceneKit nodes — no Blender
  re-export needed).
- Finger/toe-level marking (dropped, see Decisions).
