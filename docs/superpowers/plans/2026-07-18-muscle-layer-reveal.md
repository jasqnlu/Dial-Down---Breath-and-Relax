# Muscle-Layer Reveal on Region Selection

**Goal:** Replace the Body Map's synthetic candidate-box overlay with a real muscle-anatomy reveal — confirming a tap zooms in, fades the skin translucent, and shows the actual underlying muscle geometry with the relevant group(s) highlighted, sourced from Z-Anatomy.

**Architecture:** `BodyRig.showCandidates`'s synthetic `SCNBox`/`SCNSphere` markers and their hit-testing are replaced with a second mesh layer (`BodyMuscle.obj`, exported from `Z-Anatomy.blend`) whose per-group materials carry the focused/unfocused highlight and serve as the tap targets directly. Each candidate muscle keeps its own anatomical shading and gets a colour-coded **rim outline + light tint** (not a solid colour fill and not a box) so adjacent heads stay visually distinct — the focused candidate's rim/tint deepens, unfocused ones stay subtle but still legible. The existing confirm → `applyFocus` → `CandidateRailOverlay` pipeline is unchanged; only what gets drawn and hit-tested at the 3D anchor changes.

**Prototype:** `docs/mockups/bodymap-muscle-reveal.html` — interactive CSS/SVG stand-in validating this exact interaction and highlight treatment before the SceneKit build.

**Tech Stack:** Swift, SwiftUI, SceneKit/simd, Blender (Python), Swift Testing.

## Context

Today, confirming a tap dollies the camera in (`BodyRig.focus(on:)`) and overlays translucent **synthetic boxes** (`BodyRig.showCandidates`, `BodySceneView.swift:318-352`) over candidate regions — an abstract x-ray patch, not real anatomy. The app ships only a single flattened skin mesh (`BodyMale.obj`); no muscle geometry exists yet.

This builds directly on hitbox work already completed this session: `Resources/musclegroup_hitboxes.json` (40 groups) and `Resources/musclegroup_head_hitboxes.json` (24 heads) were generated from `/Users/jasonlu/Blender/Z-Anatomy.blend`, verified to match the app's normalized model space to 6 decimal places. That same file has skin and the full muscle system on one aligned rig, so it is also the source for the visual muscle mesh — no separate asset purchase needed.

## Decisions

- **Asset source:** Z-Anatomy (`Z-Anatomy.blend`), not a purchased asset. CC-BY-SA 4.0 terms already accepted for the hitbox data (attribution to BodyParts3D + Z-Anatomy; the derived model file made available under CC-BY-SA 4.0 if redistributed) — same terms extend to the visual muscle mesh.
- **Muscle mesh scope:** export only the ~64 objects already matched by the existing `classify_hitboxes.py` / `classify_head_hitboxes.py` regex rules (the 40 groups + 24 heads), not Z-Anatomy's full ~7,000-object scene. Every visible muscle chunk is then guaranteed nameable/tappable, reusing classification already proven correct (0 unmatched groups, 48/48 heads matched cleanly).
- **Box replacement:** full replacement, not just visual — hit-test the real muscle geometry, remove the synthetic boxes entirely.
- **Transparency scope (v1):** whole-mesh skin fade, not a localized per-pixel cutout. The camera is already dollied to `distance × 0.55` on just the tapped region by the time this triggers, so the rest of the body is mostly out of frame anyway.

## Global Constraints

- **Test framework:** Swift Testing (`import Testing`, `@Test`, `#expect`), never XCTest. Module `BreathRelaxStretch`.
- **Test command:** `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- **License obligation:** attribute "BodyParts3D — CC-BY 4.0" and "Z-Anatomy — CC-BY-SA 4.0" in the app's credits; make the exported `BodyMuscle.obj` available under CC-BY-SA 4.0 if redistributed.
- **Coordinate space:** Y-up, +Z-forward, height 2.0, recentred to whole-body bbox center — identical math in `BodyMeshLoader.makeTemplateBodyNode` and `Tools/blender/extract_hitboxes.py`; any new export must reuse it exactly or hitboxes/mesh will misalign.

---

## Asset pipeline (Blender → app resources)

1. **Refactor into a shared module.** Pull `HEAD_RULES` / `EXCLUDE` / `side_of()` out of `classify_hitboxes.py` and `classify_head_hitboxes.py` into `Tools/blender/muscle_classification.py`, imported by both. Verify both scripts still produce byte-identical output to the currently-shipped JSON after the refactor.
2. **New `Tools/blender/export_muscle_obj.py`** (run inside Blender against `Z-Anatomy.blend`): use the shared classification module to select exactly the objects already matched to a group or head, export to `Resources/Models3D/BodyMuscle.obj` preserving one `o`/`g` group per source object (unlike `BodyMale.obj`'s flattened export), so SceneKit creates one addressable child node per muscle piece.
3. Same script emits `Resources/musclegroup_node_names.json`: exported object name → owning `MuscleGroup` (and head, where applicable) — a direct byproduct of the classification already done for the export filter.
4. **Verify** before shipping: every `MuscleGroup` case and every `MuscleGroup.muscleHeads` key has ≥1 node in the map; every mapped name exists in the exported OBJ.

## Rendering architecture (`BodySceneView.swift`)

- `BodyModelStyle`: add `case muscle` → resource `"BodyMuscle"`.
- `BodyMeshLoader.makeTemplateMuscleNode()`: same recentre/scale math as `makeTemplateBodyNode` (factor into a shared helper), but no flattening and no single stamped material. For each child node, look up its `MuscleGroup` via `musclegroup_node_names.json` and assign a **shared cloned `SCNMaterial` per group** — muscle-tone diffuse, no tint/rim by default. One material per group means toggling its highlight affects the whole group at once.
- `BodyRig`: add `muscleNode` (hidden, opacity 0), lazily loaded via `loadMuscleLayerIfNeeded()` the first time a tap needs it.
- New `Models/MuscleNodeNames.swift`: static loader (mirrors `BodyHitVolumes.load()`) exposing both directions — node name → `MuscleGroup`, and `MuscleGroup` → node names.

## Replacing candidate boxes with real muscle hit-testing

- `BodyRig.showCandidates` (`BodySceneView.swift:318-352`): remove the synthetic box/sphere creation entirely. For each `MarkCandidate`, look up its group's node(s) via `MuscleNodeNames` and apply the mockup's two-part highlight, driven by the candidate's assigned accent colour (`CandidatePalette`, already used for the rail chips):
  - **Light tint**: blend the group's diffuse toward the accent colour (`multiply.contents` or a per-pixel diffuse lerp) — subtle for unfocused candidates, stronger for the focused one. Base anatomical shading stays visible underneath at every state, so neighbouring heads never dissolve into one solid colour block.
  - **Rim outline**: a thin colour-coded edge per candidate, since SceneKit materials have no native border/stroke. Cheapest approach — an inverted-hull outline (clone the group's geometry, cull front faces, scale outward slightly, flat-color material = accent colour) parented behind the muscle node; toggle its emission intensity for dim vs. focused, matching the mockup's `.dim`/`.hot` stroke-width and glow states.
- `handleCandidateHitTest` (line 664) and `handleTap`'s raycast path: hit-test against `muscleNode`'s child geometry instead of `"candidate:<region>"` boxes. Resolve the tapped node via the reverse lookup, accept only if that group is among the current `disambiguationCandidates`.
- `CandidateRailOverlay` is untouched — it projects each candidate's already-known 3D point via `SCNView.projectPoint`, independent of how the anchor is hit-tested.

## Transparency + reveal trigger

- Hook into `applyFocus(for:)` (`BodySceneView.swift:685-691`) — the point where the camera dolly and candidate display already converge, on every Confirm tap and every refocus.
- When candidates become non-empty: fade the skin node's material `transparency` via `SCNAction` (same ~0.5s ease as the existing camera dolly), fade in `muscleNode` (after `loadMuscleLayerIfNeeded()`) with each candidate group's tint/rim already applied per above.
- On dismiss (candidates cleared): reverse both fades, hide `muscleNode`.

## Files

**New:** `Resources/Models3D/BodyMuscle.obj`, `Resources/musclegroup_node_names.json`, `Tools/blender/muscle_classification.py`, `Tools/blender/export_muscle_obj.py`, `Models/MuscleNodeNames.swift`.

**Modified:** `Tools/blender/classify_hitboxes.py`, `Tools/blender/classify_head_hitboxes.py` (import shared classification), `Views/BodyMap/BodySceneView.swift` (`BodyModelStyle`, `BodyMeshLoader`, `BodyRig.showCandidates`, `handleCandidateHitTest`, `handleTap`, `applyFocus`).

## Verification

- Refactor safety check: after extracting `muscle_classification.py`, diff `classify_hitboxes.py`/`classify_head_hitboxes.py` output against currently-shipped JSON — must be byte-identical.
- `xcodebuild test` — `MuscleHitResolverTests` / `HitboxDataTests` stay green; add node-name coverage tests.
- `verify` skill: launch the simulator, tap a region with multiple real candidates (e.g. near the elbow — triceps heads vs. biceps heads), confirm zoom-in + skin fade + muscle mesh reveal; confirm every candidate muscle is individually distinguishable (own rim colour + light tint, base shading still visible) and the focused one's rim/tint is visibly stronger than its neighbors — compare against `docs/mockups/bodymap-muscle-reveal.html`; tap between candidates and confirm the highlight follows focus; complete a selection and confirm navigation to the exercise list still works. Screenshot for review.
