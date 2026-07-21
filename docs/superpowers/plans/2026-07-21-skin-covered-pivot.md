# Skin-Covered Body Map — Pivot Implementation Plan (Plan 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Switch the Body Map to a **skin-covered figure** from the new blend `Z-Anatomyskinjointmuscle.blend`: the resting body is a clean full-body skin; tapping a spot fades the skin to reveal grayscale muscles with the adjacency candidates colorized. Curate joints down to **6 hitbox-only regions** (no rendered joint geometry). Patch the deleted-genitalia hole in the skin.

**Architecture:** A Blender **skin-prep** step joins the 296 `Regions of human body` patches into one welded, hole-filled skin mesh. A new export emits **two layers** — `skin` (the welded body skin) + `muscle` (grayscale, `classify_group`) — plus the node map; joints are **not** exported as geometry. Hitboxes regenerate for 40 muscle groups + face zones + the 6 kept joints. `BodySceneView` reverts to a **skin-visible-at-rest → fade-to-muscle-on-reveal** rig (`skinNode` always visible, `muscleNode` hidden until a tap), reusing everything else from Plans 1–3 (adjacency `candidates()`, the node-map loader, face zones, `oldRegionMap` joint→muscle resolution, the mirrored-object winding fix).

**Tech Stack:** Blender 5.x headless Python + bmesh, Swift/SwiftUI/SceneKit, Swift Testing.

## Context: what already exists (reuse, do not rebuild)

- **Repo is clean + green at `fa87b19`** on branch `feature/muscle-layer-reveal` (the écorché single-anatomy model from the FIRST blend). This pivot replaces the rendering approach and the blend; keep the branch.
- **Reused as-is:** `RegionAdjacency` + `MuscleHitResolver.candidates()` (adjacency, no arm bleed); `MuscleNodeNames` node-map loader (layer/group/head/faceZone/joint schema); `classify_group`/`classify_head`/`classify_face_zone` in `muscle_classification.py`; `MuscleGroup.oldRegionMap` joint→muscle entries (added Plan 3 — includes Neck/Lower Spine/Hip/Shoulder Joint); the winding-flip fix in `export_anatomy.py` (`flip = det < 0`); the OBJ parser (`parseAnatomyOBJ`) and `AnatomyPiece`.
- **`BodyMale.obj` fallback:** a clean single-mesh full-body skin exists in git history (pre-`c89af0a`). If the region-patch skin cleanup (Task 1) proves too messy after tuning, `git show c89af0a~1:"Breath - Relax & Stretch/Resources/Models3D/BodyMale.obj"` recovers it as an alternative skin (it aligned with the muscle mesh via the marking system). Prefer the region-patch skin (anatomically matched) unless it can't be cleaned.

## Global Constraints

- **New source blend:** `/Users/jasonlu/Blender/Z-Anatomyskinjointmuscle.blend` (79 MB, not in repo). Blender: `/Applications/Blender.app/Contents/MacOS/Blender -b "<blend>" --python <script>`.
- **The skin lives in collection `9: Regions of human body` (296 mesh patches).** It is EXCLUDED from the view layer by default — un-exclude it (`layer_collection.exclude = False`, recursively) before selecting/joining, or the objects are unreachable.
- **Skin-prep is verified to work:** join all 296 patches → `bmesh.ops.remove_doubles(dist≈0.0015)` → `bmesh.ops.holes_fill(sides=0)` → `recalc_face_normals` → one ~33k-poly mesh. At `dist=0.0008` boundary edges went 11353→1701→820; a larger `dist` closes the residual seams/holes. TUNE `dist` up until boundary edges are minimal without visibly distorting the body (start 0.0015, try up to 0.004).
- **Coordinate space unchanged:** the OBJ is pre-normalized at export (`blender_to_app` + whole-body recentre/scale + `apply_recentre_correction`), identity-loaded. Skin + muscles + hitboxes all bake from the SAME whole-body normalization over all non-`.g` meshes → aligned by construction.
- **Winding fix applies to the skin too:** the skin is joined from mirrored patches, so keep the per-object `flip = matrix_world.to_3x3().determinant() < 0` winding reversal. NOTE: after `join()`, the merged skin is ONE object; recompute winding correctness via `recalc_face_normals` in the prep (consistent outward normals) rather than the per-object flip. Verify the skin renders evenly lit (no half-grey seam).
- **6 joint regions (hitbox-only, NO geometry):** `Neck`, `Lower Spine`, `Left/Right Hip`, `Left/Right Shoulder Joint`. Names must not collide with `MuscleGroup` raw values (they don't). All 6 are already in `MuscleGroup.oldRegionMap` (Plan 3) so they resolve to crossing muscles' exercises.
- **Grayscale muscles.** Skin material: default a soft neutral tone (reads as a person); it's one line to change to grayscale if preferred — leave a clearly-named constant.
- **Test framework:** Swift Testing only. Module `BreathRelaxStretch`. Test cmd: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`. The 4 `CuratedContentIntegrityTests` are pre-existing known-failing — NOT a regression gate.
- **Asset budget:** skin ~33k polys + muscle mesh (decimated) — target the combined `.obj` ≤ ~20 MB.
- **Simulator verification:** repo `verify` skill (XCUITest driver + screenshots); `AnatomyRevealUITest` already exists to adapt.

---

### Task 1: Curate joints to 6 (vocab + classifier + tests)

**Files:**
- Modify: `Breath - Relax & Stretch/Models/JointRegion.swift` (15 → 6 cases)
- Modify: `Tools/blender/muscle_classification.py` (`classify_joint` → only the 6)
- Modify: `Breath - Relax & StretchTests/JointRegionTests.swift`, `Tools/blender/test_classification.py`

- [ ] **Step 1: Update `JointRegionTests.swift`** expected set to the 6:

```swift
    @Test func hasExactlySixRegions() { #expect(JointRegion.allCases.count == 6) }
    @Test func containsTheExpectedNames() {
        let expected: Set<String> = ["Neck", "Lower Spine",
            "Left Hip", "Right Hip", "Left Shoulder Joint", "Right Shoulder Joint"]
        #expect(JointRegion.allNames == expected)
    }
```
(Keep `doesNotCollideWithMuscleGroups` and `isJointRecognizesMembersAndRejectsOthers`, adjusting the latter's positive case to e.g. `"Left Hip"` and negative to `"Left Elbow"`.)

- [ ] **Step 2: Replace `JointRegion.swift` cases** with exactly:

```swift
    case neck = "Neck"
    case lowerSpine = "Lower Spine"
    case leftHip = "Left Hip",   rightHip = "Right Hip"
    case leftShoulder = "Left Shoulder Joint", rightShoulder = "Right Shoulder Joint"
```
(Keep `allNames`/`isJoint`.)

- [ ] **Step 3: Restrict `classify_joint`** in `muscle_classification.py` — replace `JOINT_BILATERAL_RULES` with only Shoulder Joint + Hip, and `_spine_region` to map only cervical→Neck and lumbar→Lower Spine (drop thoracic→Upper Spine; drop elbow/wrist/knee/ankle):

```python
JOINT_BILATERAL_RULES = [
    ("Shoulder Joint", [r"glenohumeral", r"acromioclavicular", r"coracohumeral",
                        r"coraco-acromial", r"glenoid labrum", r"transverse humeral ligament"]),
    ("Hip",            [r"capsule of hip", r"iliofemoral", r"pubofemoral", r"ischiofemoral",
                        r"ligament of head of femur", r"zona orbicularis", r"acetabular"]),
]
_SPINE_LETTER = {"c": "Neck", "l": "Lower Spine"}   # thoracic (t) intentionally dropped
```
(`classify_joint`'s body is otherwise unchanged; `_spine_region` returns `None` for thoracic discs now, and the `atlanto-axial → Neck` branch stays.)

- [ ] **Step 4: Update `test_classification.py`** joint cases — assert `Left Hip`/`Right Shoulder Joint`/`Neck`/`Lower Spine` resolve, and `Articular capsule of elbow joint.l`, `Intervertebral disc T4-T5`, `Anterior talofibular ligament.l`, `Articular capsule of knee joint.l` now return `None`. Run `python3 Tools/blender/test_classification.py` → OK.

- [ ] **Step 5:** Run `-only-testing:"…/JointRegionTests"` → green. **Commit** both Python + Swift: `feat(bodymap): curate joints to 6 hitbox-only regions`.

---

### Task 2: Skin-prep + new export (`export_skin_muscle.py`)

**Files:**
- Create: `Tools/blender/export_skin_muscle.py`

**Interfaces:** Produces (in `Tools/blender/generated/`): `BodySkinMuscle.obj` (one `o BodySkin` skin group + one `o` per muscle object) and `skinmuscle_node_names.json` (`{node: {layer: "skin"|"muscle", group?, head?, faceZone?}}`).

- [ ] **Step 1: Create `export_skin_muscle.py`.** It mirrors `export_anatomy.py`'s normalization (copy `blender_to_app`, `world_aabb`, the whole-body `mesh_objects` normalization, `to_app_space`, `sanitize`, decimate handling, and the `flip = det<0` winding reversal for the muscle objects) but:
  - **Skin prep** (do FIRST, before normalization bounds so the welded skin is included in `mesh_objects`): un-exclude `9: Regions of human body`, join its 296 mesh patches into one object named `BodySkin`, then bmesh: `remove_doubles(dist=0.0015)` → `holes_fill(sides=0)` → `recalc_face_normals`. (If the visible result still has holes, raise `dist` toward 0.004.) The welded `BodySkin` is a real mesh object in the scene.
  - **Selection:** skin = the single `BodySkin` object (layer `skin`); muscles = `4: Muscular system` members via `classify_group` (layer `muscle`, + optional `classify_head`/`classify_face_zone`). Do NOT iterate the `3: Joints` collection — no joint geometry.
  - **Skin winding:** after `recalc_face_normals`, `BodySkin` has consistent outward normals; export its faces WITHOUT the per-object flip (det may be +1 post-join). Muscle objects keep the `flip` reversal.
  - **Node map:** `{node: {"layer": "skin"}}` for `BodySkin`; `{"layer":"muscle","group":…, "head"?:…, "faceZone"?:…}` for muscles.
  - Output: `Tools/blender/generated/BodySkinMuscle.obj` + `skinmuscle_node_names.json`.

  Provide the complete file by adapting `export_anatomy.py` per the above (the normalization/OBJ-emission/decimate/sanitize blocks are copied verbatim; only the collection selection + the skin-prep prologue differ).

- [ ] **Step 2:** `python3 -m py_compile Tools/blender/export_skin_muscle.py` → clean. **Commit:** `feat(blender): export_skin_muscle preps + exports welded skin + muscle layers`.

---

### Task 3: Regenerate hitboxes (6 joints) from the new blend

**Files:** Modify `Tools/blender/classify_hitboxes.py` / `classify_head_hitboxes.py` / `classify_joint_hitboxes.py` output dirs only if needed (they already target `generated/`).

- [ ] **Step 1:** In Blender, run `extract_hitboxes.py` against the new blend → `/tmp/body_part_hitboxes.json`.
- [ ] **Step 2:** `cd Tools/blender && python3 classify_hitboxes.py && python3 classify_head_hitboxes.py && python3 classify_joint_hitboxes.py`. Expected: 40 muscle groups, face zones present, and `classify_joint_hitboxes` prints only the 6 joint regions (Neck, Lower Spine, Left/Right Hip, Left/Right Shoulder Joint) — "Missing joint regions (0): []" against the reduced expected set (update the `expected` list in `classify_joint_hitboxes.py` to the 6).
- [ ] **Step 3: Commit** the classify_joint_hitboxes expected-set change: `chore(blender): joint hitboxes restricted to the 6 kept regions`.

---

### Task 4: Run the pipeline → staged assets + verify

- [ ] **Step 1:** Run `export_skin_muscle.py` in Blender against the new blend. Confirm layer counts show `skin: 1` and `muscle: ~268`, and the OBJ ≤ ~20 MB.
- [ ] **Step 2: Adapt `verify_anatomy_export.py`** → `verify_skin_muscle_export.py`: coverage (every MuscleGroup + face zone has ≥1 muscle node & box; the `skin` layer has exactly 1 node; joint box set == the 6); no excluded-system leakage; L=+x; alignment (muscle node centroids inside their region box; skip the skin node — it spans the whole body). Run it → OK.
- [ ] **Step 3: Commit** staged assets + verifier: `chore(blender): generate staged skin+muscle assets from new blend`.

---

### Task 5: Swift integration — skin-over-muscle rendering

**Files:**
- Move: `Tools/blender/generated/{BodySkinMuscle.obj → Resources/Models3D/, skinmuscle_node_names.json, the 3 hitbox JSONs → Resources/}`; delete `Resources/Models3D/BodyAnatomy.obj`, `Resources/anatomy_node_names.json`.
- Modify: `Breath - Relax & Stretch/Models/MuscleNodeNames.swift` (load `skinmuscle_node_names.json`; add `skin` to the layer vocabulary — accessors already generic).
- Modify: `Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift` (rig: `skinNode` visible + `muscleNode` hidden→revealed).
- Update: `MuscleNodeNamesTests.swift`, `HitboxDataTests.swift` (6-joint set).

**Rig rework (the core change) — in `BodyRig`:**
- Rename `anatomyNode`→`muscleNode`, `headSkinNode`→`skinNode`. At rest: `skinNode` visible + opaque, `muscleNode` `isHidden = true` (so marking taps hit the skin, and hidden geometry is excluded from hit-testing).
- `loadIfNeeded`: attach `layer=="skin"` pieces to `skinNode` (skin material — soft neutral tone via a named `skinTone` constant), `layer=="muscle"` pieces to `muscleNode` (grayscale `baseTone`).
- Replace `fadeHeadSkin(reveal:)` with `reveal(_:)` / `dismissReveal()`: on reveal — `muscleNode.isHidden = false`, animate `muscleNode.opacity 0→1` and `skinNode.opacity 1→0.12`, then `showCandidates`; on dismiss — reverse, `muscleNode.isHidden = true` on completion, `resetTints`.
- `showCandidates`/`resetTints` operate on `muscleNode` children (unchanged logic, `nodesByName` now only holds muscle pieces + the skin; only muscle pieces get tinted).
- Marking hit-test (`handleTap`) raycasts `skinNode` (the only visible surface at rest) → resolve → `onRegionTap`. The confirm-step `handleCandidateHitTest` raycasts the revealed `muscleNode`.

This is the same two-layer pattern the pre-anatomy app used (skin over muscle) — the git history before `c89af0a` (`revealMuscleLayer`/`hideMuscleLayer`/`skinNode`/`muscleNode`) is a close reference for the animation + hit-test code; adapt it to the single-OBJ `AnatomyPiece` loader.

- [ ] **Step 1:** Install assets (git mv/rm as above).
- [ ] **Step 2:** Update `MuscleNodeNames.swift` resource name to `skinmuscle_node_names`; confirm `layerByNode` carries `"skin"`/`"muscle"`. Update `MuscleNodeNamesTests`: parser builds exactly the mapped nodes; every group/head/faceZone has muscle nodes; the skin layer has exactly one node; joints have NO nodes (hitbox-only) — assert `nodesByJoint` is empty.
- [ ] **Step 3:** Rewrite the `BodyRig` layer/reveal sections + `BodySceneView.applyFocus`/dismiss per the rework above. Update `BodyModelStyle.resourceName` → `"BodySkinMuscle"`.
- [ ] **Step 4:** Update `HitboxDataTests.jointBoxesMatchJointRegionSet` to the 6-region `JointRegion.allNames` (already generic if it uses `JointRegion.allNames`).
- [ ] **Step 5:** `xcodebuild test` (focused: `MuscleNodeNamesTests`, `HitboxDataTests`, `BodyRigFocusTests`) → green, then full suite green except the 4 known. **Commit:** `feat(bodymap): skin-covered model — skin fades to reveal muscles`.

---

### Task 6: Simulator verification + tuning

Use the `verify` skill; adapt `AnatomyRevealUITest`.

- [ ] Resting figure reads as a **clean skin-covered body** (no patch seams, no groin hole, no half-grey seam). If seams/holes show, raise the skin-prep `remove_doubles` `dist` (Task 2) and re-export.
- [ ] Tap the chest → skin **fades** → grayscale muscles appear, candidates colorize (`Chest/Lats/Obliques/Abs`, no arm).
- [ ] Tap near a shoulder/hip/neck/lower-back → resolves to the joint region → its crossing muscles' candidates.
- [ ] Dismiss → skin fades back in (muscle hidden again).
- [ ] Confirm framing + no rotation regressions (BodyRigFocusTests still green). Screenshot each; commit any tuning: `chore(bodymap): tune skin material + framing`.

---

## Self-Review

**Spec coverage:** skin-covered resting + fade-to-muscle (Task 5); welded/hole-patched skin from the new blend (Tasks 2, 6); 6 hitbox-only joints, no geometry (Tasks 1, 3); grayscale muscles + adjacency colorize (reused, Task 5); face zones on reveal (reused). ✓

**Placeholder note:** Task 2's export file is described as "adapt `export_anatomy.py` per the above" rather than reproduced verbatim — the executor MUST open `export_anatomy.py`, copy its normalization/OBJ-emission/decimate/sanitize blocks unchanged, and only swap the skin-prep prologue + collection selection. Every other task has concrete code/commands.

**Risks:** (1) skin-prep `dist` tuning — the residual 820 boundary edges need a larger threshold; budget a couple of re-export/render cycles (Task 6 loop). (2) If the region-patch skin can't be cleaned acceptably, fall back to `BodyMale.obj` from git history (Context section) as the skin layer — same rig, different skin OBJ. (3) The rig rework reverts Plan 3 Task 1's visibility model; the pre-`c89af0a` git history is the reference implementation for skin-over-muscle reveal.

**Handoff:** all decisions + the verified skin-prep recipe are in project memory (`anatomy_model_replacement.md`). Start by reading that memory + this plan, then execute Task 1.
