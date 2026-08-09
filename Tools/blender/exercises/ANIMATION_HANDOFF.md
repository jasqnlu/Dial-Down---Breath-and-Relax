# Exercise Animation — Handoff for a New Session

**Last updated:** 2026-07-28
**Goal:** Give the 152 seed exercises 3D-animated demonstrations, authored in
Blender and exported for the app. Started with **"Clasped Hands Behind Back."**
Longer-term vision: an **anatomy figure that performs the stretch while the
worked muscles/joints highlight.**

This file is the context dump so a fresh chat can continue without re-deriving
everything. Read it top-to-bottom once.

---

## TL;DR / current state

- **LATEST (2026-07-28): the muscle-body + skin-head path WORKS.** New script
  `clasped_hands_behind_back_muscleonly.py` builds a **skin-head + muscle-body**
  figure from the app OBJ and animates the full clasp cleanly. Front view is
  presentable (shoulders/chest/biceps highlighted, hands clasp low at the
  midline). See "Muscle-only result" below. Two residual polish items remain:
  upper-arm muscle **stretch/drape** at the extreme elbow fold (visible in
  profile) and **hand-tendon shards** at the wrists. Not blockers.
- **Clean motion is proven** on a generic **A-pose base mesh** — the body
  deforms with no tearing. Script: `clasped_hands_behind_back_basemesh.py`.
  The one remaining issue is **pose authoring** (arms currently lift up/out
  instead of going down-and-behind to clasp) — SOLVED for the muscle-only script
  (see Gotcha #6 for the bone-axis semantics).
- **The anatomy model animates but the SKIN TEARS at the arms** because it's
  modeled arms-down. Script: `clasped_hands_behind_back_bodymap.py`. The
  skinning itself is now correct (was silently broken — see Gotcha #1). The
  muscle-only script sidesteps this entirely by dropping the torso/limb skin.
- **The unified "animate anatomy + highlight muscles" vision is viable** via
  the app's existing `BodySkinMuscle.obj` (skin + 268 named muscle objects),
  NOT via the giant raw merged blend. Muscle groups map cleanly to bones
  (all 41 mapped, 0 fallbacks); **joint-blend weighting** fixes the muscle
  separation. Confirmed this session.

---

## The three scripts (all in `Tools/blender/exercises/`)

Each is a **paste-in Blender script** (run in the *Scripting* tab, fresh file —
they clear the scene) AND runnable headless. Each writes a `.glb` (animated
model), a `.blend` (editable scene), and a `*_log.txt` to
`Tools/blender/generated/exercises/`. They surface success/errors as an
in-Blender popup + the log file (double-clicked Blender has no visible console).

| Script | Model | Status |
|---|---|---|
| `clasped_hands_behind_back.py` | Self-built blocky "segment box" figure | ✅ Works. Pure prototype to prove the rig→keyframe→export pipeline with zero external assets. |
| `clasped_hands_behind_back_bodymap.py` | App's welded anatomy shell (`BodySkinMuscle.obj`) | ⚠️ Animates, but **skin tears at the arms** (arms-down mesh). Skinning fixed via distance weighting. |
| `clasped_hands_behind_back_basemesh.py` | `FinalBaseMesh.obj` (A-pose) | ✅ **Clean deformation, no tearing.** Pose needs re-authoring (arms go up/out, not behind). |
| `clasped_hands_behind_back_muscleonly.py` | App OBJ, **skin clipped to a head cap + 268 muscles** | ✅ **Recommended path.** Per-muscle group→bone bind + joint-blend weighting + muscle highlight + hand/foot mitts. Front view presentable; only faint wrist tendon wisps remain in profile. Writes .glb/.blend/log + 3 PNG renders (rest_front, peak_front, peak_side). |

---

## Muscle-only result (2026-07-28) — how the recommended script works

Figure = **head skin cap + 268 muscle objects** built from the app OBJ; the
full-body skin shell is dropped (that shell is what tore). Pipeline highlights:

1. **Import as separate objects** (not joined-then-welded like the bodymap
   script). Keeps muscles individually bindable + highlightable.
2. **Skin → head cap.** The OBJ's `BodySkin` is a *full-body* shell (Y −0.92→
   +1.0). Auto-detect the neck as the narrowest skin cross-section in the
   0.72–0.93 height band (came out at frac ≈0.864), delete skin below it →
   ~3.2k-vert head cap that never tears (head barely moves in this stretch).
3. **Per-muscle bone bind.** Each muscle's `group` (from
   `skinmuscle_node_names.json`) → a bone via a keyword table (`group_to_bone`).
   All 41 groups map, 0 fallbacks. L/R falls out of the "Left/Right" prefix.
4. **Joint-blend weighting** (the fix for muscle separation): each muscle vertex
   is inverse-distance weighted (power 4, top-2) over the muscle's
   **joint-adjacent bone set only** = primary bone + its parent + its children.
   Mid-muscle verts stay ~rigid; verts near a joint blend to the neighbour, so a
   deltoid stretches across the shoulder instead of detaching. The restricted
   candidate set is what stops the global-nearest-bone "cape tear" (Gotcha #2).
5. **Highlight.** Muscles whose group matches `WORKED_KEYWORDS`
   (shoulder/chest/bicep for this exercise) get an orange material; rest grey;
   head cap gets skin tone. 2 shared muscle materials → 2 slots after join.
6. Join muscles → one skinned "Muscles" mesh; head cap stays separate. Export
   GLB (verified skins:1, anims:1) + blend + renders.

**Works:** no skin-cape tearing, shoulder stays connected, highlight tracks the
muscles, GLB skinning valid. Front view (the app's shipping angle) is presentable.

**Polish pass done (2026-07-28):**
- **Elbow eased** — forearm flexion dropped 50°→36° (see solved pose in Gotcha
  #6). Killed the upper-arm muscle drape; arm now reads as a normal silhouette.
- **Hands + feet → convex-hull mitts.** The atlas hands/feet are dozens of thin
  splayed finger/toe meshes that strand when posed. Each side's `Hand`/`Foot`
  group is joined + `convex_hull_object()`'d into one solid mitt (rigid-ish,
  joint-blend weighted to `forearm`/`shin`). Clean feet wedges + hand mitts.
- **Forearm hull = DEAD END, reverted.** Hulling the forearm (to remove its
  finger-tendon wisps) comes out a flat ugly paddle — a limb segment's convex
  hull bridges its widest points into a slab (merged-with-hand or separate, same
  result). Forearms keep their real geometry + joint-blend instead.

**Residual (minor, profile-only, not blockers):** faint finger-tendon "wisps" at
the wrist — the `flexor/extensor digitorum` tendons are tagged `Forearm` but run
to the fingertips, so they can't be hulled without flattening the forearm. Real
fix if ever wanted: detect + strip just the high-aspect-ratio tendon objects,
keep the forearm belly. Also the two hands slightly overlap where they clasp at
the midline (cosmetic).

---

## Models / assets

| Asset | Path | Notes |
|---|---|---|
| **App anatomy OBJ** | `Breath - Relax & Stretch/Resources/Models3D/BodySkinMuscle.obj` | Welded skin shell + **268 muscles as separate named `o` groups**. Pre-normalized (Y-up, height 2). **Arms-down** → tears when arm-animated. |
| **Muscle tag map** | `Breath - Relax & Stretch/Resources/skinmuscle_node_names.json` | Maps each `o` node → `{layer, group, ...}`. 41 muscle groups. This is what makes muscles **individually highlightable**. |
| **Base mesh** | `Tools/blender/incoming/FinalBaseMesh.obj` | Clean single-manifold male, **A-pose**, 24,461 verts, has normals. User-supplied (extracted from a `.rar`). Great for motion; no anatomy. |
| **Source anatomy blend** | `/Users/jasonlu/Blender/Z-Anatomyskinjointmuscle.blend` | The blend the app OBJ is generated from (via `../export_skin_muscle.py`). |
| **"Merged" anatomy blend** | `/Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend` | ⚠️ **2.07M verts, 4,372 meshes + 951 curves + 1,660 text labels, NO armature** (76 MB; opened + inventoried 2026-07-28). Full Z-Anatomy atlas. **Its only "skin" (collection `9: Regions of human body`) is HEAD/FACE region patches — `Frontal/Nasal/Buccal region`, `Hairs of head` — NOT a body skin.** Its one genuinely unique asset the app OBJ lacks is **joint geometry** (`3: Joints`, 480 meshes: intervertebral discs, ligaments, membranes). Everything else (skin, muscle) is cleaner in the app OBJ. **Only touch this file if you need joints as highlightable geometry** — then extract just collection 3. |

Collections in the merged blend worth knowing: `1: Skeletal system`,
`3: Joints` (480 meshes), `4: Muscular system` (789), `9: Regions of human
body` (skin, but scattered/unwelded + junk anchor planes + text labels).

---

## Muscle-group → bone mapping (confirmed, enables clean weighting + highlight)

The 41 groups in `skinmuscle_node_names.json` map cleanly onto a simple rig:

| Bone | Muscle groups |
|---|---|
| `upperarm.L/R` | Biceps, Triceps, Shoulder (deltoid) |
| `forearm.L/R` | Forearm, Hand |
| `chest` | Chest, Lats, Trapezius, (upper) Obliques |
| `spine` | Spinal Erectors, Lower Back, Abs |
| `hips` | Glutes, Hip Flexors, Adductors |
| `thigh.L/R` | Quadriceps, Hamstrings |
| `shin.L/R` | Calves, Tibialis, Foot |
| `head` | Head, Front/Back Neck |

**Why this matters:** assigning each *named muscle object* 100% to its bone
avoids the distance-guessing that tears the arms. Highlighting = give target
muscle objects a colored material. (Skin is one welded shell → still needs
distance weighting → may still crease slightly at the shoulder.)

---

## Hard-won gotchas (DO NOT re-learn these the slow way)

### 1. `parent_set(ARMATURE_AUTO)` silently produces ZERO weights on the anatomy mesh
Bone-heat ("Automatic Weights") needs a clean closed manifold. The welded skin
+ overlapping muscle geometry breaks it — but in Blender 5.1.2 it **raises no
error**, just creates empty vertex groups. Result: glTF exports `skins: 0`, the
mesh stays static while only the bones animate ("blocky things move, body
doesn't"). **Fix used:** author weights ourselves — `bind()` in the scripts does
nearest-segment inverse-distance weighting over the TOP_K (=2) nearest bones,
guaranteeing 100% coverage and an exportable skin. Verify with the weight-count
check below.

### 2. Arms-down mesh → arm bones hug the torso → weight bleed → "cape" tearing
On the app anatomy OBJ, torso/waist vertices are Euclidean-close to the arm
bones (arms hang alongside the body), so they get arm weight and drag a sheet of
skin when the arm lifts. **A-pose meshes avoid this** (air between arm and
torso). This is THE reason the base mesh works and the anatomy shell doesn't.
Region-based (per-muscle) weighting sidesteps it for muscles; skin is the
residual problem.

### 3. Pose authoring on A-pose arms is unintuitive (SOLVED for the vertical rig — see #6)
Pose-bone `rotation_euler` is in **bone-local** space. For diagonal A-pose arm
bones, "swing behind the back" is not a clean single-axis rotation. Base-mesh
`POSES` make the arms lift up/out, not down-and-behind. For the muscle-only rig
(arms hang straight down) the axes are clean — see Gotcha #6.

### 4. `~/Downloads` reads HANG from this background session (TCC)
Reading file *contents* under `/Users/jasonlu/Downloads` blocks forever (stat/ls
work). `~/Blender/` and the repo read fine. Always bound Downloads-touching
commands: `perl -e 'alarm 6; exec @ARGV' <cmd>`. To get a file out of Downloads,
have the **user drag it into the repo via Finder** (Finder-osascript automation
is also blocked for the bg process). See memory `icloud-desktop-tcc-gotcha`.

### 5. Rendering headless: TRACK_TO constraint doesn't evaluate; set camera rotation directly
Use `BLENDER_WORKBENCH` engine (solid shading, no materials/lights needed) and
set `cam.rotation_euler` directly (front = `(radians(90),0,0)` looking `-Y`;
side = `(radians(90),0,radians(90))`). Call `bpy.context.view_layer.update()`
before each render. OBJ importer maps file Y-up → Blender Z-up.

### 6. Arm-bone euler axes for the vertical rig (this is how the clasp pose was solved)
The muscle-only rig's arm bones hang **straight down** (local Y = world −Z). For
`upperarm.{L,R}` and `forearm.{L,R}`:
  * **DEPTH DIRECTION (learn from the mistake): −Y is the FRONT/chest side, +Y is
    BEHIND.** The azimuth-0 camera sits at −Y and shows the chest, so front = −Y.
    An earlier diagnostic mislabeled this (+Y=front) and every "extension" swung
    the arms FORWARD — the hands ended up in front of the chest and the
    "behind-the-back" look was faked by filming from behind. Confirm front/back
    before trusting any Y sign.
  * **local X** = world +X → **+X rot swings the arm BACK / behind (+Y)** = shoulder
    extension; **−X = forward**. For the FOREARM, **−X flexes the elbow** to fold
    the hand in behind the spine.
  * **local Z** = world +Y → **+Z = toward the midline for the LEFT arm**
    (adduction); mirror to **−Z for R**.
  * **local Y** = twist.
Don't eyeball depth — solve numerically. `solve_pose.py` (scratchpad) sweeps the
angles and reports the **wrist world position**; target = **behind (y ≈ +0.15..
+0.18, just inside the back surface), midline (|x|≈0), low (z≈0.95)** so the torso
occludes the hands from the front camera. Shipped clasp: upperarm `(+28, 0, ±12)`,
forearm `(−34, 0, ±22)`, rendered at `CAMERA_AZIMUTH = 38`.

---

## Tooling / commands

**Blender CLI:** `/Applications/Blender.app/Contents/MacOS/Blender` (v5.1.2)

Run a script headless (regenerates the .glb/.blend):
```bash
BLENDER=/Applications/Blender.app/Contents/MacOS/Blender
"$BLENDER" -b --python "Tools/blender/exercises/clasped_hands_behind_back_basemesh.py" 2>/dev/null
```

Open a saved scene + run a render/inspect script against it:
```bash
"$BLENDER" -b "Tools/blender/generated/exercises/<name>.blend" --python <script.py>
```

**Verify a .glb actually has a skin + animation** (parse the JSON chunk):
```python
import json, struct
d=open("<file>.glb","rb").read(); clen,_=struct.unpack("<II",d[12:20])
g=json.loads(d[20:20+clen])
print("skins",len(g.get("skins",[])),"anims",len(g.get("animations",[])))
# skins==0 => skinning is broken (see Gotcha #1)
```

**Verify vertex weights exist** (open the .blend headless):
```python
import bpy
b=bpy.data.objects["Body"]
print(sum(1 for v in b.data.vertices if any(g.weight>0 for g in v.groups)),
      "/", len(b.data.vertices), "weighted")
```

**App integration next step:** convert `.glb → .usdz` for SceneKit/RealityKit,
e.g. Reality Converter or `xcrun usdconvert in.glb out.usdz`. Export uses
`export_yup=True` for SceneKit's Y-up. See the app-integration plan:
`docs/superpowers/plans/2026-07-12-exercise-video-animation.md` (proposes an
`Exercise.animationIdentifier` field + a SceneKit card sibling to the existing
`ExerciseMediaCard`/`localVideoURL` video path).

---

## Rig shape (shared by all scripts)

~12-bone humanoid: `hips → spine → chest → head`, `chest → upperarm.{L,R} →
forearm.{L,R}`, `hips → thigh.{L,R} → shin.{L,R}`. The base-mesh and bodymap
scripts **auto-fit** bones to the mesh (measure bounds / detect landmarks like
hands, shoulders, hips, feet) so the rig scales to any model. Animation loop is
0..120 @ 30fps (4s): neutral → clasp → peak → hold → back to neutral.

---

## Where we are now (2026-07-28) + open decisions

**Path 1 (the recommended experiment) is DONE and validated** — see
`clasped_hands_behind_back_muscleonly.py` and "Muscle-only result" above.
Muscle-body + skin-head animates cleanly with joint-blend weighting; the
"show skin at all?" sub-question is answered: **head skin only** (drop the
body skin that tears). Resolved decisions:
- ✅ Source = app `BodySkinMuscle.obj`, NOT the merged blend (its skin is head
  patches only; only joints are unique there).
- ✅ Muscles are bone-mappable (all 41 groups) and don't tear with per-muscle
  bind + joint-blend weighting.
- ✅ Pose authoring solved numerically (Gotcha #6).

**Polish pass DONE** (elbow eased, hand/foot mitts, forearm-hull dead-end
reverted — see "Muscle-only result"). Front view is presentable; only faint
profile wrist wisps remain.

**Next candidate steps:**
1. **App integration — DONE (2026-07-30, Approach A = baked video).** Not usdz/
   SceneKit: the loop renders to a muted mp4 (`render_demo_video()` +
   `Tools/blender/encode_mp4.swift`, since this Blender has no FFMPEG) and routes
   through the app's looping-video slot via `Exercise.animationName` → `demoVideoURL`
   → `ExerciseMediaCard` (portrait 4:5) + an `ExerciseRow` `LoopingVideoThumbnail`.
   Per-exercise angle via `CAMERA_AZIMUTH`. Clasped-Hands shipped (azimuth 38).
   See memory `exercise-animation-app-integration`.
2. **Per-exercise authoring:** this script hard-codes one exercise's pose +
   worked-muscle set. Generalize to author the other 151 (pose library keyed by
   exercise; worked muscles from the exercise's muscle tags).
3. **Joints (later / optional):** app models joints as hitboxes
   (`JointRegion.swift`, `musclegroup_hitboxes.json`), not geometry. Only if
   joint highlighting is wanted → extract collection 3 from the merged blend.

---

## Second batch (2026-08-02): shared lib + 3 more exercises

Generalized the pipeline off `clasped_hands_behind_back_muscleonly.py` (still
kept, unmodified, as a working reference) into **`_lib.py`** — every function
from that script (import/normalize/rig-build/weighting/render/export) minus
the per-exercise config. A new exercise is now a ~50-line script that sets
`EXERCISE`, `VIDEO_NAME`, `CAMERA_AZIMUTH`, `WORKED_KEYWORDS`, `POSES` (and
optionally `ORTHO_SCALE_MULT`), adds `Tools/blender/exercises/` to
`sys.path`, and calls `L.run(globals())`. Still paste-in compatible — the
`sys.path.insert` line works identically pasted into the Scripting tab.

Shipped: `neck_flexion_chin_to_chest.py`, `standing_forward_fold_ragdoll.py`,
`left_standing_side_bend.py`. All three reuse the exact rig/skinning/
highlight machinery — only pose angles, camera azimuth, and worked-muscle
keywords differ per exercise.

### Walkthrough: Neck Flexion Stretch (Chin-to-Chest) — first of this batch

The simplest possible case: **one bone (`head`), one rotation axis.** Chosen
deliberately as the first of the batch to validate the generalized `_lib.py`
against exercise #1's known-good output before attempting anything with more
moving parts.

- **New axis convention needed.** All prior gotchas (esp. #6) were solved for
  the ARM bones, which hang straight down (local Y = world −Z). The vertical
  bones (`head`, `chest`, `spine`) point straight UP (local Y = world +Z) —
  a different bone orientation, so the arm-bone sign conventions do NOT
  transfer. Solved numerically with a throwaway probe script (build the rig,
  apply a lone +20° local-axis rotation to `head`/`chest`/`spine`, print the
  bone tail's world position for each of the 3 axes): **local X pitches a
  vertical bone forward** (+X moves the tail toward −Y, i.e. front, and
  slightly −Z) — the sign is POSITIVE for forward-pitch, opposite of the arm
  bones' "+X = swing back" rule. Local Z bends the bone sideways (toward
  world −X). Local Y is twist, as with the arms.
- **Highlight precision:** the atlas has separate `Back Neck` / `Front Neck`
  muscle objects; `WORKED_KEYWORDS = ("back neck",)` (not the broader
  `"neck"`) highlights only the muscle actually stretched by a chin tuck.
- **Camera:** shot from the side (`CAMERA_AZIMUTH = 90`) — a front camera
  looks straight down the pitch axis, so a nod reads as foreshortening
  instead of visible motion.
- **No new failure modes.** Single rigid bone, no joint-spanning muscle, no
  tearing risk — this one worked first try. Rendered result: clean forward
  nod, `Back Neck` lights up orange, no artifacts.

### The other two — what came up

- **Standing Forward Fold (Ragdoll):** stacks the SAME forward-pitch rotation
  on `spine` + `chest` (children down the `hips -> spine -> chest` chain) so
  the torso hinges at the hips while legs stay planted. Two things that bit:
  (1) **first render clipped the head and left huge dead space** — the fixed
  camera framing (`ortho_scale = height * 1.15`) was tuned for an upright
  rest pose, but the peak fold pushes the silhouette's depth extent (world Y)
  far past the rest-pose bounding box, so the head landed near the frame
  edge. Fixed by adding an `ORTHO_SCALE_MULT` override (`_lib.py`'s
  `setup_render` now takes a multiplier, default 1.15; this exercise ships
  1.7). (2) **arms need to counter-rotate to hang world-vertical** —
  `upperarm.{L,R}` are children of `chest`, so they inherit its pitch; since
  every rotation here is about local X (which stays parallel to world X
  through the whole chain — pitching about X doesn't change what "X" is),
  the chest's total world pitch is just `spine + chest` added up, and giving
  the upperarms that sum negated exactly cancels it. Matches the instruction
  "let your head, neck, and arms hang heavy."
- **Left Standing Side Bend:** local Z instead of local X (sideways instead
  of forward). Almost shipped a sign error here: the rendered peak frame was
  briefly misread as bending the wrong way by eye. Settled it two ways
  instead of trusting the image: (1) numeric — logged the `head` bone's peak
  world position (`x = −0.603`) — and (2) a marker-cube probe rendering a
  red cube at world +X and a blue one at −X through the actual front camera,
  which showed **+X renders on screen-right**. Cross-checked against the
  real mesh: `Left Obliques` centroid is at x=+0.13, `Right Obliques` at
  x=−0.13 (read directly off the imported OBJ, not assumed from the rig's
  own `.L`/`.R` bone-naming convention, which is a separate, arbitrary
  choice made in `build_armature`). Conclusion: positive local-Z bends the
  torso toward the subject's own right (screen-left) — correct for this
  exercise, since "Left Standing Side Bend" means bending right to stretch
  the left flank. **Lesson: don't eyeball left/right off a front-view render
  — a face-on camera mirrors it. Verify with a coordinate probe.**

### Fixed while at it
`show_popup()` now no-ops when `bpy.app.background` is true — calling
`popup_menu` with no window manager (any headless `-b` run) doesn't raise a
Python exception, it **segfaults Blender on exit** (after every file is
already written, so it's harmless but noisy — every headless run of the
original clasped-hands script had this crash too, unnoticed because it
happens post-export).

## Third batch (2026-08-03): 10 more exercises

Generated 10 more exercises reusing `_lib.py` and only already-validated bone-axis
conventions (head/spine/chest pitch ±X, side-bend ±Z, twist ±Y; the clasped-hands
arm-swing angles) — deliberately stayed off the hip/thigh/shin bones, which have
no proven pose-authoring convention yet. Shipped: `neck_extension_look_up`,
`chin_tuck_forward_head_reset`, `right_standing_side_bend`,
`standing_back_extension`, `cobra_stretch_prone_press_up`,
`left_seated_spinal_twist`, `right_seated_spinal_twist`, `reverse_prayer_stretch`,
`left_wall_bicep_stretch`, `right_wall_bicep_stretch`. All 10 exported valid
skinned glTF and rendered clean (no tearing) on first attempt — see
`Tools/blender/generated/exercises/THIRD_BATCH_INSTRUCTIONS.md` for the full
per-exercise writeup and instructions.

**New gotcha:** the twist exercises (first use of local-Y on the *vertical*
bones) exposed a blind spot in the `run()` sanity check — it logs the pose bone's
peak **tail world position**, but a bone twisting about its own long axis barely
moves its tail, so the log reads as a no-op even when the twist is real and
correctly mirrored between the L/R pair. Verified correctness by eyeballing the
rendered PNGs instead (confirmed the L/R pair are genuinely mirrored, not
identical) — don't trust the tail-position log for twist-only poses.

## Rotation audit (2026-08-05/07): Wall Bicep Stretch fix + seated leg pose

Audited all 14 shipped animations against their exercise's actual instructions
(see `docs/superpowers/plans/2026-08-05-rotation-animation-audit.md`). Found
`left_wall_bicep_stretch` / `right_wall_bicep_stretch` never rotated the
torso despite the exercise being "rotate your torso away from the wall" —
fixed by adding a `chest`/`spine` local-Y twist (small, 8-15 deg) alongside
the existing arm pitch, reusing the seated-twist sign convention (positive Y
= twist right, matching `left_seated_spinal_twist`'s direction).

**New proven convention: a static seated leg pose on `thigh.{L,R}`/
`shin.{L,R}`.** These bones had "no proven pose-authoring convention" as of
the third batch. Probed with a throwaway script
(`Tools/blender/exercises/_seated_probe.py`, deleted after validating —
recreate from this note if needed) applying a *constant* (not per-frame
animated) offset held across the whole clip:

```python
"thigh.L": (r(-90), 0, 0),
"thigh.R": (r(-90), 0, 0),
"shin.L":  (r(90), 0, 0),
"shin.R":  (r(90), 0, 0),
```

Result confirmed by both the tail-position log and eyeballing the render:
thigh tail moved from knee-height to hip-height at world Y = -0.42 (i.e.
swung forward to horizontal — recall azimuth-0's camera sits at world -Y, so
-Y = front, confirming hip *flexion* not extension), and shin tail landed
directly below at floor-adjacent height, i.e. the lower leg hangs straight
down from a forward-bent knee exactly like sitting on a chair/floor edge.
Render showed a convincing seated silhouette with no visible mesh tearing,
though the knee crease geometry is a bit blockier/pinched than the small-
angle poses used elsewhere (largest rotation applied anywhere in the rig
so far) — acceptable at the app's render style/resolution.

**Sign convention (thigh/shin, hip-flexion-and-knee-fold only, NOT yet
validated for anything dynamic like a swing/circle):** thigh and shin hang
down like the arm bones (not vertical like spine/chest/head), and empirically
follow the *same* local-X convention as the arms: thigh -90 = hip flexes
forward to horizontal (mirrors the arm's "-X = forward" for both L/R, no
sign flip needed between sides since this is directly forward, not lateral);
shin's follow-up local-X is relative to the thigh's already-rotated frame,
and needs the *opposite* sign (+90) to fold the lower leg back down rather
than up toward the torso — do not assume shin mirrors thigh's sign.

Applied to `left_seated_spinal_twist.py` / `right_seated_spinal_twist.py`
(previously rendered as a standing torso rotation despite the exercise name
— the docstring said as much: "The rig has no seated pose, so this reads as
a standing torso rotation"). The `_SEATED` leg offset is held constant at
every keyframe (0/30/60/90/120) with the existing twist keyframes layered on
top for spine/chest, same pattern as the probe.

**Still unproven:** anything that moves the legs *dynamically* mid-clip
(a lunge, a hip circle, a leg swing) — this convention only covers a static
held pose. Tier C in the rotation-audit plan (Standing Hip Circles, Runner's
Lunge with Rotation, World's Greatest Stretch, Dynamic Standing Leg Swings,
Cossack Squat) still needs its own probe before authoring.

## Related project context

- Body Map architecture / SceneKit loading: `Breath - Relax &
  Stretch/Views/BodyMap/BodySceneView.swift`; memory `bodymap-3d-skin-architecture`,
  `anatomy-model-replacement`.
- Blender export pipeline that produces the app OBJ: `Tools/blender/export_skin_muscle.py`
  (welds skin patches, bakes app-space coords, tags muscles). Run `graphify
  query "..."` for codebase questions (see project `CLAUDE.md`).
- Copyright/asset-sourcing analysis (Z-Anatomy is CC-BY-SA — share-alike
  concern for a paid app): `docs/superpowers/plans/2026-07-12-exercise-video-animation.md`.
