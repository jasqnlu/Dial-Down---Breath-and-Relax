# Single Anatomy Model — Body Map Replacement

**Goal:** Replace the Body Map's two-mesh (skin + muscle) system with **one always-visible anatomy model** — grayscale muscles + stretchable joints for the body, plus an aesthetic **skin head** — all exported from `Z-AnatomyMuscle-Joint-Skin-Merged.blend`. This adds **joints as tappable stretch regions**, connects the **face zones to their real facial muscles** (retiring the placeholder circles), fixes the **arm↔torso candidate bleed** with an anatomical adjacency map, and fixes the **slight-rotation-on-select** bug. At rest the whole figure reads **black-and-white**; on confirm/zoom the anatomically-nearby muscles **colorize** and the skin head **fades**.

**Prototype:** `docs/mockups/bodymap-anatomy-reveal.html` — interactive CSS/SVG stand-in validating this exact interaction (tap anywhere → nearest region → adjacency candidates → joint/facial highlight → head-skin fade).

**Tech stack:** Swift, SwiftUI, SceneKit/simd, Blender (Python), Swift Testing.

## Source-file reality (verified 2026-07-19)

`Z-AnatomyMuscle-Joint-Skin-Merged.blend` (~79 MB) is the **full Z-Anatomy master atlas**, not a curated subset: 6,987 objects across every system (skeleton, cardiovascular, lymphoid, nervous, visceral, …). Two consequences drive the export design:

- **Blender visibility flags are NOT a usable selector.** 692 meshes are "visible," but that set is dominated by the full skeleton and 160 lymph nodes, while the muscle bodies and all joint capsules are mostly hidden. **Selection must be by collection membership + name classification, never by hide-flags.**
- **The relevant geometry lives in three collections**, all confirmed present and cleanly named (Z-Anatomy `.l`/`.r` side suffixes, English/Latin anatomical names):
  - `4: Muscular system` — 789 muscle-body meshes (the shipped `BodyMuscle.obj` already derives from these).
  - `3: Joints` — 480 capsule/ligament/disc meshes (0 visible by default).
  - `Regions of head` — 94 surface patches that tile into the face/scalp/ears/hair (`Frontal region`, `Parietal region`, `Temporal region`, `Occipital region`, `Buccal/Oral/Nasal/Orbital region`, ear parts, `Hairs of head`), sitting at z≈1.5–1.66. **This is the "skin head."** Z-Anatomy has no object literally named "skin"; this collection is it.

Only the **head** is skinned — there is no torso/limb skin in the blend. So the resting body is bare muscle+joints (grayscale) and the head wears the skin head (also grayscale): an écorché body with a normal-looking face.

## Context

Today the Body Map (`Views/BodyMap/`) renders two meshes on one rig: `BodyMale.obj` (skin, always visible) and `BodyMuscle.obj` (muscle, revealed under a skin-fade during confirm-step disambiguation — shipped 2026-07-18 on `feature/muscle-layer-reveal`). Marking raycasts the skin, resolves the point via `MuscleHitResolver` against `BodyHitVolumes.all` (40 muscle groups + 24×2 heads + 8 hand-placed joint boxes), and confirm surfaces up to 4 candidates chosen by **3D-distance radius**. That radius is the source of the reported bug: arms hang close to the torso in the anatomical pose, so a chest/leg tap wrongly offers arm muscles. Joints resolve to hitboxes but have **no visible geometry** (they were excluded from the muscle mesh), and face zones (Eye/Temple/Jaw/Forehead) fall back to **solid `cand-dot` spheres** because no facial-muscle nodes were mapped to them.

This spec makes the merged blend the single source for both the rendered model **and** the hitboxes, and replaces the separate skin body with the muscle anatomy + skin head.

## Decisions

- **One model replaces both meshes.** `BodyMale.obj` and `BodyMuscle.obj` are retired. The body is always the muscle+joint anatomy; the only skin is the head.
- **Resting state is grayscale.** Muscles, joints, and skin head all render black-and-white at rest. Color is reserved for highlight.
- **Skin head is aesthetic and fades on reveal.** The `Regions of head` collection covers the facial muscles at rest (so the resting figure has a normal face, not a skinned skull). On any zoom/confirm it fades (to ~0.12 opacity), exposing the facial muscles for highlighting. For body taps the head is out of frame, so the fade is a visual no-op there.
- **Highlight = colorize the nearby muscles.** On reveal, only the adjacency-selected candidate muscles (and joint capsules / facial muscles when relevant) get tint+emission; everything else stays grayscale.
- **Joints kept (stretchable only):** neck/cervical, shoulder (glenohumeral + acromioclavicular), elbow, wrist, spine (thoracic + lumbar, grouped), hip, knee, ankle. **Removed:** finger/toe joints, cranial/ear/tiny articulations, and everything non-stretchable. Governing rule: *if you can't stretch it, remove it.*
- **Joint hitboxes come from real joint geometry**, replacing the 8 hand-placed boxes: capsule meshes where they exist (`Articular capsule of {glenohumeral,acromioclavicular,elbow,radiocarpal,hip,knee} joint.l/.r`), `Ankle joint.j` + ankle ligaments, and per-level intervertebral discs for neck (`C2-C3…C7-T1`) and lower spine (`L1-L2…L5-S1`).
- **No bones, organs, nerves, vessels, or lymph nodes** in the export.
- **Candidates come from an anatomical adjacency map**, not a 3D-distance radius.
- **Face zones highlight their underlying facial muscles:** Eye→orbicularis oculi (orbital + palpebral parts), Temple→temporalis, Jaw→masseter (deep + superficial parts), Forehead→frontalis. All four confirmed present in the blend. The `cand-dot` fallback is retired for these (kept only for any region that still has no geometry).
- **Rotation bug is fixed** as part of this work (it lives in the same focus/reveal code).
- **Dedicated joint-mobility exercise content is OUT OF SCOPE** → sub-project #2. This spec makes joints tappable, highlightable, and resolvable; until #2 lands a joint resolves to the stretches of the muscles that cross it (graceful fallback, no new content).

## Global constraints

- **Test framework:** Swift Testing (`import Testing`, `@Test`, `#expect`), never XCTest. Module `BreathRelaxStretch`.
- **Test command:** `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`
- **Blender invocation:** headless — `/Applications/Blender.app/Contents/MacOS/Blender -b "<blend>" --python <script>`; source blend at `/Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend` (not in the repo; large + gitignored).
- **License:** attribute "BodyParts3D — CC-BY 4.0" and "Z-Anatomy — CC-BY-SA 4.0" in credits; the exported model is CC-BY-SA 4.0 if redistributed.
- **Coordinate space:** Y-up, +Z-forward, height 2.0, recentred to the whole-body bbox center — mesh and hitboxes are baked from the SAME merged-blend normalization (`blender_to_app` axis map + whole-body recentre/scale + `apply_recentre_correction`), so they align by construction. Skin head and muscles share the blend's world coords, so they align after the same uniform normalization.
- **Asset budget:** the shipped `.obj` must stay small (the previous muscle mesh was 13 MB at decimate 0.15). Joints (~16 capsule meshes) and facial muscles (~8) add little; the skin head is ~17k polys total (8.6k of which is `Hairs of head`). Target ≤ ~18 MB for the merged set; tune the per-object decimate ratio (and decimate `Hairs of head` hard) to hit it.
- **Pre-existing known-failing tests:** the 4 `CuratedContentIntegrityTests` fail on `main` for unrelated content-drift reasons (content-pack names vs `SeedData.json`); they are not a regression gate for this work.

---

## Component 1 — Blender export (`export_anatomy.py`)

Evolve `Tools/blender/export_muscle_obj.py` into `export_anatomy.py`, run against the merged blend. It **iterates the three whitelisted collections** (`4: Muscular system`, `3: Joints`, `Regions of head`) — ignoring visibility — and tags four object classes via the shared `muscle_classification.py` (extended):

- **Muscles** — existing `classify_group` / `classify_head` (40 groups + 24 heads), unchanged, applied to `Muscular system` members.
- **Facial muscles** — a new `classify_face_zone(name)` mapping orbicularis oculi→`Eye`, temporalis→`Temple`, masseter→`Jaw`, frontalis→`Forehead` (side-aware where bilateral). These are muscles that ALSO carry a face-zone tag.
- **Joints** — a new `classify_joint(name)` selecting only the kept joints' capsule/ligament/disc objects and bucketing them into region names (`Left Elbow`, `Neck`, `Lower Spine`, …). Everything else (fingers, toes, cranium, non-stretchable) returns `None` and is dropped.
- **Head-skin patches** — the `Regions of head` members, tagged `headSkin`.

Bones, organs, nerves, vessels, lymph, and unmatched objects are excluded (they are simply never iterated, since only three collections are whitelisted). The script emits:

- `Resources/Models3D/BodyAnatomy.obj` — one `o` group per kept object, decimated, pre-normalized to the app model space (identity-load, as `BodyMuscle.obj` was). Replaces `BodyMuscle.obj`; `BodyMale.obj` is deleted.
- `Resources/anatomy_node_names.json` — `{ node → { group?, head?, joint?, faceZone?, layer: "muscle"|"joint"|"headSkin" } }`.

**Verify at export time:** every `MuscleGroup` case, every muscle head, every kept joint region, and every face zone has ≥1 renderable node; every mapped name exists in the OBJ; the whitelisted-collection selection excludes all skeleton/organ/nerve/vessel/lymph names.

## Component 2 — Hitbox regeneration (single source)

`classify_hitboxes.py` / `classify_head_hitboxes.py` re-run against the merged blend to regenerate `musclegroup_hitboxes.json` and `musclegroup_head_hitboxes.json`. A new `classify_joint_hitboxes.py` derives `joint_hitboxes.json` from the **real joint geometry** (capsules where present, `Ankle joint.j` + ankle ligaments, and per-level cervical/lumbar intervertebral discs), bucketed by `classify_joint` into one bbox per joint region — replacing the 8 hand-placed boxes and covering the expanded joint set. Face-zone hitboxes come from the facial-muscle geometry (so a tap on the face resolves to a zone). All boxes use the identical normalization as the mesh → mesh ⟷ hitbox alignment holds by construction (regression-tested: every node center inside its region box, as verified for the muscle mesh).

`BodyHitVolumes.all` continues to load these JSONs; the smallest-volume containment + nearest-center fallback in `MuscleHitResolver.regionName` is unchanged.

## Component 3 — Region vocabulary

- **Muscles:** `MuscleGroup` enum unchanged.
- **Joints:** a `JointRegion` set (the kept joint region names). Joints are NOT `MuscleGroup` cases; they are their own region strings, resolved through `BodyHitVolumes` like the current joints. `RegionExerciseResolver` maps a joint to the union of its crossing muscles' stretches until sub-project #2 supplies dedicated content.
- **Face zones:** `MuscleGroup.headZones` (Eye/Temple/Jaw/Forehead) unchanged as vocabulary, but they now own facial-muscle node geometry via the node map.

## Component 4 — Anatomical adjacency (`RegionAdjacency`)

New `Models/RegionAdjacency.swift`: a hand-authored, symmetric adjacency map — region name → the anatomically-connected regions that may appear together as candidates (`"Left Chest" → ["Right Chest","Abs","Left Obliques","Left Shoulder", <its heads>]`; `"Left Elbow" → ["Left Biceps","Left Triceps","Left Forearm"]`; etc.). `MuscleHitResolver.candidates(near:)` changes: resolve the primary region by containment (unchanged), then draw neighbors from `RegionAdjacency[primary]` **filtered to those whose hitbox is actually near the tap** (a light distance sanity check, not the sole selector), capped at `maxCandidates`. This removes the arm↔torso bleed while staying pose-independent. Heads still drop their redundant parent (existing `parentOfHead` filter).

## Component 5 — Rendering & reveal (`BodySceneView.swift`)

- `BodyModelStyle` collapses to a single `.anatomy` resource (`BodyAnatomy`). `BodyMeshLoader` parses it with the existing contiguous-OBJ parser into per-object `SCNNode`s; nodes are tagged by layer (`muscle` / `joint` / `headSkin`) from the node map.
- **Grayscale base.** All nodes render black-and-white at rest (neutral desaturated material, e.g. grayscale diffuse / low-chroma). This is the default look for muscles, joints, and the skin head.
- `BodyRig`: one `anatomyNode` (always visible) holding muscle + joint children; a `headSkinNode` holding the head patches. The old `skinNode` / `muscleNode` two-layer split and the whole-body skin fade are removed.
- **Reveal** (`applyFocus`): zoom to the dot (unchanged), **colorize the candidate regions' nodes** (per-node tint+emission over the grayscale base, extended to joint capsules and facial muscles), and **fade `headSkinNode`** to ~0.12 opacity on any focus. Dismiss reverses the fade and clears tints (back to full grayscale). `revealMuscleLayer`/`hideMuscleLayer` become `fadeHeadSkin(reveal:)`.
- Highlight lookups (`MuscleNodeNames`, renamed/extended to `AnatomyNodeNames`) resolve a candidate region (group / head / joint / face zone) to its node set; hit-testing resolves a tapped node to the matching current candidate (head/joint preferred over group). The `cand-dot` fallback remains only for any region with zero geometry (should be none after this work).

## Component 6 — Rotation-bug fix

Symptom: after confirming/selecting, the whole figure appears to rotate slightly. Diagnose in `BodyRig.focus(on:)` + the reveal path — likely the camera `look(at:)` retarget (pitch/roll from the y-lift) or an unintended `rigNode` euler change rather than a pure dolly. Fix so focus is a pure dolly+pan onto the dot with no apparent roll, and pin it with a test asserting `rigNode.eulerAngles` is unchanged across a focus (and, if the camera pose is the cause, that its up-vector stays world-up).

## Files

**New:** `Tools/blender/export_anatomy.py`, `Tools/blender/classify_joint_hitboxes.py`, `Resources/Models3D/BodyAnatomy.obj`, `Resources/anatomy_node_names.json`, `Models/RegionAdjacency.swift`, `Models/AnatomyNodeNames.swift` (evolves `MuscleNodeNames.swift`).

**Modified:** `Tools/blender/muscle_classification.py` (`classify_joint`, `classify_face_zone`, head-region tagging, collection-whitelist helpers), `classify_hitboxes.py` / `classify_head_hitboxes.py` (re-run vs merged blend, collection-based selection), `Resources/musclegroup_hitboxes.json` / `musclegroup_head_hitboxes.json` / `joint_hitboxes.json` (regenerated), `Views/BodyMap/BodySceneView.swift` (single model, grayscale base, head-skin fade, joint/facial colorize, `focus` fix), `Models/BodyHitVolumes.swift` (`candidates` → adjacency), `Views/BodyMap/BodyMapView.swift` (any joint-candidate wiring).

**Deleted:** `Resources/Models3D/BodyMale.obj`, `Resources/Models3D/BodyMuscle.obj`, `Resources/musclegroup_node_names.json`.

## Verification

- **Export/data:** coverage tests — every `MuscleGroup`, muscle head, kept joint region, and face zone has ≥1 node in the map AND ≥1 hitbox; every mapped node exists in the OBJ; no skeleton/organ/nerve/vessel/lymph name leaked into the export; every node center lies inside its region hitbox (alignment); L/R convention holds (Left = +x).
- **Adjacency:** unit tests — `candidates(near:)` for a chest tap never returns a forearm/hand region; an elbow tap returns the joint + biceps/triceps/forearm; symmetry (adjacency is mutual).
- **Rotation:** test that a `focus(on:)` leaves `rigNode.eulerAngles` unchanged.
- **Parser:** the OBJ parses into exactly the mapped node set, each with real triangles (as for `BodyMuscle.obj`).
- **`xcodebuild test`** stays green except the 4 pre-existing `CuratedContentIntegrityTests`.
- **Simulator (`verify` skill):** resting figure reads grayscale with a normal (skinned) face; tap the chest → confirm only chest/abs/oblique/shoulder candidates colorize (no arm); tap the elbow → joint highlights as a capsule + crossing muscles; tap the face → skin head fades and a facial muscle highlights; no slight-rotation on select. Screenshot each against the mockup.
- **Asset size** ≤ ~18 MB; camera framing still frames the height-2 model correctly (retune `defaultCameraDistance` only if the merged model's proportions shifted).

## Out of scope (→ later specs)

- **Sub-project #2:** dedicated joint-mobility exercise content (author + tag drills in `SeedData`, extend `RegionExerciseResolver` for joints).
- Back/rear-facing anatomy parity beyond what the merged model already provides is assumed equivalent to today; not separately addressed here.
