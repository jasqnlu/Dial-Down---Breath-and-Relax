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
pipeline).

## Decisions made

- **Replace both interactions** (tap-to-mark and freehand-derived marking)
  with a single tap-based flow. Freehand drawing is removed entirely.
- **Tap cycles sensation type.** The user picks a sensation (existing
  `SensationColor` palette) first, then taps muscles to mark them with that
  sensation; tapping a marked muscle again unmarks it.
- **Old ink/drawing code is deleted**, not left dormant: `AnnotationStroke`,
  `AnnotationStore`, the live-draw `Canvas`, brush/eraser tool UI, and the
  saved-ink rendering layer in `BodyFigureCanvas.swift`.
- **Left/Right is anatomical, not screen-side.** The 2D map used screen-side
  ("mirror") naming — "Left Biceps" meant the arm on the viewer's left
  (`HumanFigureView.swift:35`). That convention is only coherent from a fixed
  front view; in 3D the hit volumes rotate with the body, so a
  screen-side-named box points at the *wrong* arm the moment the user rotates
  to the back. From this feature on, "Left Biceps" means the user's actual
  left arm, at every camera angle. The string vocabulary is unchanged (names
  still match `Exercise.targetBodyParts`), only which physical side each name
  refers to — so exercise matching is unaffected. See "Data layer" for the
  concrete relabeling.
- **Marking unlocks free rotation.** Hit-testing raycasts against the skin
  mesh, which works at any camera angle (SceneKit's `hitTest` resolves to the
  nearest surface along the ray, so occlusion is handled for free on a closed
  mesh) — there's no need to lock rotation to front/back during marking
  anymore.
- **Marked regions render as marker dots**, not translucent volumes. A
  translucent box intersecting the skin mesh renders as a literal box
  poking through the body, with transparency-sorting artifacts on top.
  Instead each mark places a small emissive sphere in the sensation's color
  at the tapped surface point; the chip list below the figure carries the
  region names (existing `MarkedAreasBanner` pattern).
- **Joints get ~8-10 hand-placed hit volumes** (elbows, knees, wrists,
  ankles, L/R) alongside the 40 muscle groups, since "my knee hurts" is a
  real use case the Blender muscle data doesn't cover on its own. Joint
  volumes are named with the legacy region names ("Left Elbow", "Right
  Knee", …) so they flow through the existing `MuscleGroup.oldRegionMap`
  translation — see "Marking data model".
- **Finger/toe-level marking is dropped.** Marking granularity becomes
  hand/foot as a whole, matching the rest of the redesign (muscle groups,
  not individual muscles or digits).

## Architecture

### Coordinate space (load-bearing definition)

All hit volumes, mark records, and marker positions live in **normalized
model space**: the space *after* `bodyNode`'s recenter/scale is applied —
equivalently, **`rigNode`-local space** (`bodyNode`'s parent frame). This is
the space `musclegroup_hitboxes.json` is expressed in (pivot = whole-body
bbox center, scale = 2.0/height — `BodySceneView.swift:79-89`). Two traps
this definition avoids:

- `bodyNode`-**local** coordinates are raw OBJ units (pre-pivot, pre-scale,
  multi-meter ZBrush export scale) — never use them for hit volumes or
  markers.
- Rig rotation is factored out for free: `rigNode` itself carries the
  turntable Y-rotation, so converting a world-space point into
  `rigNode`-local space yields the same coordinates regardless of how the
  body is rotated.

### Data layer

- `musclegroup_hitboxes.json` (`Tools/blender/`) — 40 entries keyed by
  `MuscleGroup` raw value, each `{min: [x,y,z], max: [x,y,z]}`, an
  axis-aligned box in normalized model space.
- **Left/right relabeling (one-time data fix).** The committed JSON currently
  has every "Left *" box at negative-x. The model faces +Z and SceneKit is
  right-handed (+x = viewer's right at front view), so negative-x is the
  figure's anatomical *right*: the labels are anatomically swapped (they
  follow Z-Anatomy's `.l`/`.r` suffixes, which land on the mirror side in
  app space; the z axis is confirmed correct — chest boxes are z-biased
  forward). Fix by **swapping the "Left *" ↔ "Right *" keys in the committed
  JSON** with a one-off script — not by re-running the pipeline, because
  `classify_hitboxes.py` reads an uncommitted `/tmp/body_part_hitboxes.json`
  intermediate and re-running requires Blender plus the .blend source. Also
  swap the suffix→group side assignment in `classify_hitboxes.py` (the
  `side != 'l'` / `side != 'r'` guards) so a future regeneration reproduces
  the committed convention, with a comment explaining why.
- **Vertical-offset verification (before trusting alignment).** App
  normalization puts the skin-mesh bottom at y = −1.0, but the JSON foot
  boxes bottom out at y = −0.913. Likely cause: `extract_hitboxes.py` pass 1
  computes the whole-body bbox over *all* anatomy meshes in the .blend,
  while the app normalizes the skin-only ZBrush OBJ — different bboxes,
  different center/scale. Before implementation trusts the data: (a) run a
  one-time debug visualization pass in the simulator that temporarily
  renders the boxes visibly over the skin (this also visually confirms the
  L/R swap: at front view, the box labeled "Left Biceps" must sit on the
  *viewer's right*); (b) if the offset is confirmed material, fix it in the
  extraction pipeline by normalizing against the skin mesh's bbox — never
  with a runtime fudge factor.
- A new small hand-authored `joint_hitboxes.json` (~10 entries: elbow, knee,
  wrist, ankle × L/R, keyed "Left Elbow", "Right Ankle", …) in the same
  coordinate space and format. Positions can be derived by inspecting
  adjacency with the neighboring muscle boxes already in
  `musclegroup_hitboxes.json` (e.g. elbow sits between the biceps/triceps
  boxes' lower y-bound and the forearm box's upper y-bound), then verified
  visually in the same debug pass.
- Both files get bundled as app resources (same pattern as `SeedData.json`).

### Hit-testing

Tap resolution is a two-stage pipeline: SceneKit finds *where* on the body
the user tapped; pure Swift math decides *what* that point is.

1. **Skin-mesh raycast.** `BodySceneView` migrates from SwiftUI's
   `SceneView` (which hides the underlying view) to a thin
   `UIViewRepresentable`-hosted `SCNView`. A tap runs `SCNView.hitTest`
   against the scene — the only geometry is the skin mesh, so the first hit
   is the correct, occlusion-respecting 3D surface point. No hidden hit-box
   nodes exist in the scene graph, and no `ignoreHiddenNodes` option is
   needed.
2. **Convert to normalized model space.** The world-space hit point is
   converted into `rigNode`-local space via `convertPosition` (see
   "Coordinate space" above — this factors out the rig's rotation).
3. **`MuscleHitResolver` (new, pure Swift).** Takes the normalized point and
   the ~50 loaded boxes (SIMD/vector math only, no SceneKit node types):
   - point-in-box containment over all boxes;
   - among containing boxes, the **smallest-volume box wins** — joint boxes
     are small and nested inside/between big muscle boxes, so they win
     automatically without priority lists;
   - if *no* box contains the point (the skin surface sits outside the
     muscle layer in places), fall back to the **nearest box center**.
   Returns the region name. Fully unit-testable with no simulator.

Why not SceneKit hit-testing against hidden `SCNBox` nodes: the AABBs
overlap heavily (e.g. "Right Chest" spans z −0.119…0.142 — nearly the full
torso depth), so nearest-box-face ordering mis-attributes taps (tapping the
back can "hit" the chest box first). Containment + smallest-volume is
deterministic and testable.

**Gesture coexistence.** Marking mode now runs tap-to-mark, drag-to-rotate,
and pinch-zoom *simultaneously* (previously marking locked rotation). The
`SceneView` → `SCNView` migration re-plumbs the existing drag/magnify
gestures; the tap recognizer must not fire on drags (standard
tap-vs-pan disambiguation — a tap is a gesture that never exceeded the drag
threshold).

### Highlight rendering

- Each mark renders as a small emissive sphere ("marker dot") in the
  sensation's color, positioned at the mark's stored surface point.
- Marker dots are parented under **`rigNode`** (a dedicated `marksNode`
  child keeps them tidy) — *not* under `bodyNode`. Children of `bodyNode`
  inherit its ~2.0/height scale (sphere radii would shrink by that factor)
  and would need raw-OBJ-unit positions; under `rigNode` the dots take
  normalized-space coordinates directly and still rotate with the body.
- Unmarking a region removes its dot; changing a region's sensation recolors
  it.

### Marking data model

- Replace `AnnotationStore`/`AnnotationStroke` with a single record type:

  ```swift
  struct BodyMark: Codable {
      let sensationID: String        // SensationColor.id
      let point: SIMD3<Float>        // tapped surface point, normalized model space
  }
  // persisted store: [String: BodyMark]  — region name → mark
  ```

  One mark per region, facing-independent (a muscle is the same muscle from
  the front or the back — a correctness improvement over the old
  independently-defined front/back `BodyRegion` sets).
- **Persistence is net-new.** Marks are *transient* today:
  `BodyMapLaunchState.initialMarkedRegions` ignores its `savedRegions`
  argument and always returns `[]`, and nothing in the marking flow ever
  writes `bodymap.markedRegions` (the only writer is a `SeedMigrator`
  legacy-name migration whose output is never read back into the UI). The
  new store persists the `[String: BodyMark]` dictionary JSON-encoded under
  a new UserDefaults key, `bodymap.markedSensations`. **No migration** from
  `bodymap.markedRegions`: there is nothing live to migrate, and
  resurrecting stale never-displayed marks would be a regression. The dead
  legacy read path (`BodyMapLaunchState` and the `bodymap.markedRegions`
  read in `BodyMapView.onAppear`) is deleted with the rest of the old
  system.
- Downstream consumers (the "Find Exercises" flow) keep reading
  `markedRegions: Set<String>`, now derived from the dictionary's keys.
  Muscle names already match `Exercise.targetBodyParts` (both are
  `MuscleGroup` raw values). Joints flow through the mechanism that already
  exists: `RegionExerciseResolver` (`BodyMapComponents.swift`) routes every
  marked-region string through `MuscleGroup.migrate`/`oldRegionMap`, which
  *already* maps "Left Elbow" → ["Left Forearm"] and "Left Knee" →
  ["Left Quadriceps"]. Extend `oldRegionMap` in `MuscleGroups.swift` with
  the missing joints and enrich the existing two:
  - "Left/Right Wrist" → same-side Forearm
  - "Left/Right Ankle" → same-side Calves, Tibialis, Foot
  - "Left/Right Elbow" → same-side Biceps, Triceps, Forearm (enriched)
  - "Left/Right Knee" → same-side Quadriceps, Hamstrings, Calves (enriched)

  No new fallback structure is introduced.

### Removed

- `BodyAnnotationOverlay.swift`'s drawing-tool UI: the brush/eraser picker
  and its sensation color palette (the tap flow presents its own
  sensation picker; only the `SensationColor` palette definition survives).
- `AnnotationStroke`, `AnnotationStore`, and the live-draw + saved-ink
  `Canvas` layers in `BodyFigureCanvas.swift`.
- `BodyRegion`, `frontRegions`, `backRegions`, and the hand/foot
  finger/toe-level region constants in `HumanFigureView.swift`.
- The rotation lock during marking (`interactive: false` path tied to
  marking mode) in `BodySceneView.swift`.
- `BodyMapLaunchState` and the dead `bodymap.markedRegions` read path in
  `BodyMapView.swift` (see "Marking data model").

## Testing

- A regression test asserting every "Left *" box in
  `musclegroup_hitboxes.json` (and `joint_hitboxes.json`) sits on
  **positive-x** (the figure's anatomical left) and every "Right *" box on
  **negative-x** — the extraction shipped with this inverted once already;
  the test pins the anatomical convention permanently.
- A box-union sanity test: the union of all hit boxes falls within
  [−1, 1] in y and roughly matches expected body proportions (guards
  against the whole-body-vs-skin bbox normalization mismatch recurring).
- `MuscleHitResolver` unit tests: containment resolution, smallest-volume
  tiebreak (a point inside both a joint box and an enclosing muscle box
  resolves to the joint), nearest-center fallback for points outside every
  box. Pure geometry — no simulator needed.
- One-time debug visualization pass in the simulator (temporarily render
  the boxes visibly) verifying box↔skin alignment and the L/R relabeling
  before the marking UI is built on top.
- Manual simulator verification (per the `verify` skill) that tapping a
  visually-obvious muscle (e.g. the figure's left bicep) marks
  "Left Biceps", at multiple rotation angles, front and back; and that a
  drag rotates without dropping a mark.

## Out of scope for this pass

- Re-exporting the Blender model to carry real per-muscle mesh geometry
  (this design uses simplified box proxies, built from already-extracted
  bounding-box data, resolved in pure Swift — no Blender re-export needed).
- Finger/toe-level marking (dropped, see Decisions).
