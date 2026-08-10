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
the existing arm pitch, reusing the seated-twist sign convention (believed at
the time to be "positive Y = twist right", matching `left_seated_spinal_twist`).

> **⚠️ That sign was wrong** — and so was the seated twist it copied. `+Y`
> twists toward the subject's own LEFT. Corrected 2026-08-08; see the
> "Twist direction" section below for the probe and the fix.

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

## Twist direction (2026-08-08): the documented sign was BACKWARDS

**`+Y` on a vertical bone twists toward the subject's own LEFT, not right.**
Everything written before this section that says otherwise is wrong.

How the error survived: the third batch verified its twist exercises by
eyeballing the rendered PNGs and "confirming the L/R pair are genuinely
mirrored, not identical." That proves *symmetry*, not *direction* — a pair
that both twist the wrong way is still perfectly mirrored. The tail-position
log can't help either (a bone twisting about its own long axis barely moves
its tail), so nothing ever actually pinned the sign down.

Settled with `_twist_probe.py` (throwaway, deleted after use — recreate from
this note). The trick is to measure a point that *does* move under a torso
twist: the shoulder, i.e. the head of `upperarm.{L,R}`, which are children of
`chest`. With `chest` local-Y = +45:

```
REST                 upperarm.L head = (+0.230, +0.000, +1.533)
chest local-Y = +45  upperarm.L head = (+0.163, +0.163, +1.533)
```

The left shoulder moved to **y = +0.163**, i.e. BACKWARD (world −Y is the
front). Left shoulder back + right shoulder forward = rotation toward the
subject's own left. Cross-checked against mesh ground truth, not bone naming:
`upperarm.L`'s head sits at x = +0.230, and the real `Left Obliques` centroid
is at x = +0.13, so world +X genuinely is the subject's left.

**Corrected convention: `−Y` = subject's right, `+Y` = subject's left.**

Four shipped animations were rotating backwards and have been fixed:
`left_seated_spinal_twist` ("twist to the right"), `right_seated_spinal_twist`
("twist to the left"), and both wall bicep stretches ("rotate away from the
wall"). `left_seated_spinal_twist`'s camera also moved 45 → 315, since the
old azimuth was framed around the wrong-way rotation.

**Lesson to generalise: mirrored is not correct.** For any bilateral pair,
verify the ABSOLUTE direction of one side against the exercise's written
instructions, then mirror. Checking only that L and R differ will happily
pass two backwards animations.

## Fourth batch (2026-08-08): Tier A of the rotation audit

Shipped 12 new exercises, all on proven axes:
`seated_neck_rotation`, `seated_neck_rolls`,
`left/right_chin_to_shoulder_diagonal_stretch`,
`left/right_scalene_neck_stretch`, `left/right_doorway_bicep_stretch`,
`left/right_wall_corner_pec_stretch`,
`seated_spinal_rotation_overhead_reach_left/right`.
26 of 217 exercises now have animations (was 14).

### New gotchas from this batch

**1. Prefer `local-X` (flexion) over `local-Z` (abduction) on arm bones.**
Gotcha #2 explains why the source mesh tears when arms lift: it's modeled
arms-down, so torso vertices sit Euclidean-close to the arm bones. Lifting an
arm *sideways* drags that neighbouring torso sheet outward into the classic
"cape"; swinging it *forward* moves the arm off the torso surface instead of
across it. Measured in practice: 85° of abduction on `upperarm` stretched the
pec into a flat sheet, and 155° stretched the lat into a huge triangular
cape. Re-authoring the same poses as forward flexion (`−X`, up to −150°)
rendered cleanly. Shoulder flexion is also the anatomically correct path for
an overhead reach, so this is rarely a compromise.

**2. Camera azimuth and pose are coupled — a proven pose can still render as
garbage.** The static seated leg pose only reads from azimuth 45+. The thigh
points along world −Y, so any camera near azimuth 0 looks straight down its
long axis and the leg collapses into an unreadable blob. The neck family is
therefore rendered STANDING (their cameras are chosen for head legibility,
and sitting is incidental to a neck stretch — unlike the seated twists, where
bracing against folded legs is what isolates the spine).

**3. Watch cumulative forward pitch on the head skin cap.** spine 45 + chest
26 + head 20 = 91° drove the head cap down inside the chest mesh. Keep the
total under ~60° or stop pitching the head.

**4. Read the INSTRUCTIONS for direction, never the exercise name.** The
naming convention is not consistent across families. `Left Standing Side Bend`
names the side *stretched* (it bends right), but `Seated Spinal Rotation with
Overhead Reach (Left)` and `Left Standing Reach-Through Twist` say "rotate
your torso to the left" — they name the *direction*. Four exercises in this
batch would have been silently backwards if authored off the name.

### Deferred out of Tier A (the audit plan over-classified these)

The plan listed these as "proven conventions, ready to author now", but each
needs a base body position the rig has never represented:

| Exercise | Blocker |
|---|---|
| Left/Right Thread the Needle | starts **on hands and knees** — no quadruped pose convention. Approximating it as a standing twist would render identically to Standing Reach-Through Twist. |
| Left/Right Supine Chest Opener (Open Book) | **lying** — no supine pose convention |
| Left/Right Standing Reach-Through Twist | scripts authored and kept, but NOT shipped: three passes could not make the cross-body reach read as travelling across the body toward the opposite ankle. Cross-midline adduction collides with the torso (arms-down mesh, no clearance). See the scripts' own docstrings. |

Also note the audit plan's "Tier A batch (10 exercises)" undercounts — it
counted table rows, but most rows are L/R pairs. Tier A was really 18
exercises; 12 shipped, 6 deferred as above.

## Supine pose probe (2026-08-09): base pose + two of three follow-ups solved, 4 exercises shipped

Ran the Tier B "supine / lying pose" experiment the rotation-audit plan
flagged as highest-value (would unblock Supine Chest Opener, Supine Spinal
Twist, and Supine Figure-4, six exercises total). First pass shipped nothing
(three follow-on techniques all failed — see the "NOT solved" writeups
below, kept for the record since the failures themselves are useful data).
**Second pass fixed two of the three** with different techniques and
shipped 4 of the 6 exercises: `right/left_supine_chest_opener.py`
(side-lying, via an object-level roll instead of a second hips pose-bone
rotation) and `right/left_supine_spinal_twist.py` (flat-on-back, via a
direct `thigh` swing instead of a hips-twist-plus-counter-rotation). Only
Supine Figure-4 (L/R) remains blocked — the ankle-cross problem is a
genuinely different failure mode (mesh stretching from bone-distance, not a
rotation-composition or tearing-angle problem) and wasn't revisited.

**Proven: `hips` local-X = −90° (held constant across the whole clip) tips
the ENTIRE rig — spine/chest/head/arms/legs, everything downstream in the
parent chain — from standing to lying flat.** Validated numerically (a
throwaway `_supine_probe.py`, deleted after use — recreate from this note):
at rest, hips/spine/chest/head tails all sit at x=0, climbing z from 1.07 to
1.92. At `hips` local-X = −90, they all land at the SAME z (0.958) with y
climbing from 0 to 0.958 — a flat horizontal line, exactly a lying silhouette.
`+90` produces the mirror (also flat, but the front of the torso ends up
facing the ground instead of the sky — see below).

**Face-up (supine) vs face-down (prone) — the sign that matters:**
`hips` local-X = **−90 → supine (face up)**, confirmed by rendering (below);
`+90 → prone (face down)`. This follows the same "+X = forward pitch"
convention already documented for spine/chest/head (forward = world −Y) —
tipping forward past horizontal lands face-down, tipping backward lands
face-up. Unlike the twist-direction sign (Finding 4), this one was right on
the first guess, but was still verified rather than assumed, per the
handoff's own process.

**Camera: top-down, not the usual azimuth-around-vertical-axis orbit.**
Once the figure is lying flat, an "azimuth" camera (which orbits a vertical
axis at a fixed height, built for a standing figure) has nothing useful to
frame — a lying figure is roughly flat in one plane. A camera positioned
directly above the figure's center, pointed straight down (`rotation_euler =
(0, 0, 0)` — a bare Blender camera's un-rotated view direction is already
−Z, i.e. top-down, which is *why* `camera_for_azimuth` needs `rot=(90,0,th)`
to reach its normal level shots), reads cleanly: head at the top of the
portrait frame, feet at the bottom, matching the app's 4:5 clip aspect
almost exactly. Rendered and eyeballed — full front-of-body muscle detail
visible, face clearly pointing at the camera (confirming face-up), no
tearing. This is the convention to reuse for any future supine exercise.

**First-pass failures (kept for the record — useful negative results):**

1. **Side-lying roll, for Supine Chest Opener.** Read the actual instructions
   before trusting the exercise name: "Supine Chest Opener" instructs *"Lie
   on your right/left side"* — side-lying (lateral), not flat-on-the-back.
   The rotation-audit plan filed this under "the supine pose" without
   checking that; it needed its own, different base pose. First attempt —
   layering a `hips` local-Y rotation on top of the local-X −90 (hypothesis:
   X tips flat, a subsequent Y "rolls" the now-horizontal body over onto its
   side, the same way a person rolls over in bed) — **was wrong.** Rendered
   `hips = (−90, −90, 0)`: the body stayed face-up, just reoriented 90° in
   the horizontal plane. Euler XYZ composition on a bone already at −90 on X
   does not behave like an intrinsic "roll around the new local axis" the
   way the numbers suggested it should.

2. **Coupled thigh/shin tilt ("windshield wipers"), for Supine Spinal
   Twist.** First attempt: twist `hips` local-Y and counter-rotate `spine`
   local-Y by the same amount, hoping the two cancel and leave the upper
   body visually fixed. **They don't cancel** — probed numerically
   (`hips_y=+25, spine_y=−25`) and the spine/chest/head tails moved
   substantially (e.g. spine.x went from 0 to −0.146), proving simple
   sign-negation across a parent/child Euler pair isn't equivalent to
   canceling the parent's rotation once the parent already carries a large
   unrelated rotation (the −90 base pitch). Second attempt: swing
   `thigh.{L,R}` local-Z directly at 25° — kept the torso fixed (never
   touched) but visibly pinched/tore at the hip crease, the same
   "abduction tears geometry" failure mode documented for arm bones
   (Gotcha #1, fourth-batch section above), generalizing to the hip joint.

**Second pass — both fixed with different techniques, not more of the same:**

1. **Side-lying roll — fixed via an OBJECT-level rotation, not a second
   pose-bone rotation.** The failure above was stacking a second Euler
   component onto the `hips` POSE BONE, which composes in the bone's own
   already-rotated local frame — not the world-space "roll" the numbers
   implied. Instead, after posing `hips` local-X = −90 (pose bone, as
   before), rotate the ARMATURE OBJECT ITSELF around world Y (the axis the
   body now lies along, established by the base-pose probe): `arm_obj.
   rotation_euler = (0, r(roll_deg), 0)`. This is a genuinely different
   space — object-level transforms compose in true world space, applied
   after the internal pose — and it worked on the first retry: probed
   numerically (X and Z swap between bones, Y — the length axis — stays
   fixed) and confirmed by rendering, a clean side-lying profile with the
   face correctly visible (confirming face-up-on-the-side, not face-down).
   Sign: `roll_deg = +90` puts the RIGHT side up (lying on the LEFT side),
   `−90` puts the LEFT side up — verified by comparing bone-tail Z, not
   assumed. Landed in `_lib.py` as `apply_supine_base(arm_obj, roll_deg)`
   and `run_supine(cfg)`, a parallel entry point to `run()` for anything
   built on the supine base (recomputes camera bounds from the POSED mesh
   instead of the standing rest pose, and uses a top-down camera instead of
   the azimuth-orbit one `run()` assumes).
   Shipped: `right_supine_chest_opener.py` (`ROLL_DEG=90`, right arm
   sweeps from forward at shoulder height through overhead to behind via
   local-X flexion, `chest` gets a shallow twist alongside) and
   `left_supine_chest_opener.py` (mirror, `ROLL_DEG=-90`).

2. **Windshield-wipers tilt — fixed by using a much smaller angle, not a
   different axis.** The tearing at 25° was real, but re-tested at 10-15°
   and it was clean (this is the same lesson as the arm-abduction gotcha:
   the failure is angle-dependent, not axis-forbidden — smaller flexion-
   adjacent angles are fine, it's specifically *large* abduction-like
   swings that tear). Shipped at 20° at the peak keyframe (12° at the
   quarter-keyframes) — visible without tearing. Also **dropped the
   literal 90° "arms in a T-shape"** the instructions describe: reproduced
   the same known abduction-tearing at that angle (a "cape" forming at both
   armpits), so the shipped version uses 45° instead — a readable
   approximation of "arms out to the sides," not a literal T. Sign for the
   knee-swing and head-turn axes both confirmed by a coordinate probe
   against the written instructions (not eyeballed off the render, which is
   a mirrored top-down view and easy to misread — this is the same trap
   Finding 4 already documents). Shipped: `right_supine_spinal_twist.py`
   (knees fall left via `thigh` local-Z negative, head turns right via
   `head` local-Y negative) and `left_supine_spinal_twist.py` (mirror).

**Third pass (same session) — fixed too, via a pipeline-level rigging fix,
not a per-exercise pose trick:**

3. **Ankle-over-knee cross, for Supine Figure-4.** Swinging one `shin` bone
   across the midline (large local-Z on top of its normal knee-fold) to
   approximate resting an ankle near the opposite knee stretched the foot
   "mitt" (the convex-hulled hand/foot club described in `_lib.py`) into
   thin splayed webbing. This was NOT the same failure as the windshield-
   wipers tearing (that was angle-dependent and fixed by going smaller); an
   ankle cross needs a large swing to actually reach, so "use a smaller
   angle" wasn't available. **Root cause turned out to be generic, not
   specific to this pose:** mitts were weighted with the same joint-blend
   distance function (`blend_weights()`) used for actual stretchy muscle
   geometry — appropriate for a muscle belly that needs to deform across a
   joint, wrong for a mitt, which is a solid convex hull that shouldn't
   deform at all. A large swing left the mitt's far vertices pulled toward
   whichever second-nearest bone the blend picked at the ROTATED pose, and
   a rigid hull pulled by two competing weights is exactly what stretches
   into webbing. **Fix:** added `rigid_weight()` to `_lib.py` — 100% of
   every vertex to the mitt's one owning bone, no distance blending — and
   routed the hull-building loop through it instead of `blend_weights()`.
   Re-rendered the ALREADY-SHIPPED chest-opener/spinal-twist clips first to
   confirm no regression (hands/feet still hold shape at the wrist/ankle
   seam), then retried the same -45 to -60 degree ankle swing that
   produced webbing before: held its shape cleanly through the whole
   range. Getting the swing to not tear was one fix; getting it to read as
   an anatomically clean "figure-4" (ankle resting near, not just crossing
   near, the opposite knee) took several more rendered iterations of
   hand-tuning `thigh`+`shin` together (the crossing leg needs the THIGH
   externally rotated to open the knee out, not just a shin swing — tried
   shin-only first, reads as a kick, not a cross). The shipped values are
   the best rendered result this session, not a numerically-derived pose —
   a reasonable approximation, not precise ankle-on-knee contact. Shipped
   as `right/left_supine_figure_4.py`. Arms are kept in a relaxed forward
   position rather than animating the "reach through and clasp the
   opposite thigh" hand detail, which is out of scope for this pass.

Since the fix is a pipeline-level rigging change (not a pose trick specific
to Figure-4), it should also de-risk any FUTURE exercise needing a large
hand/foot swing to touch another body part — Thread the Needle's under-body
arm reach (Tier B) being the next candidate that would have hit the same
wall.

**Net result: all 6 target exercises shipped** (`right/left_
supine_chest_opener`, `right/left_supine_spinal_twist`,
`right/left_supine_figure_4`), verified in the running app via
`SupineExercisesUITests` (all six open and play in `ExerciseMediaCard` with
correct muscle-target chips), unit tests green.

## Quadruped pose probe (2026-08-09): first hands-and-knees pose, Thread the Needle shipped

Followed up on the "should de-risk Thread the Needle" note above by
actually attempting it — a genuinely new base pose, not a variant of the
supine work, since nothing in the rig had ever been posed on all fours
(originally Tier A in the rotation-audit plan, moved to Tier B 2026-08-08:
"no quadruped pose convention exists").

**First attempt (rotation only) put the pelvis floating in mid-air with the
legs and arms dangling, nowhere near the ground.** Bending `spine` forward
90°+ (reusing the proven "+X = forward pitch" convention) correctly
horizontals the torso, but `hips` — the unparented root bone — doesn't
move in world space under its OWN rotation, and I hadn't rotated it
(deliberately, to keep the legs from tipping the way they did in the
supine work). Result: the pelvis stayed pinned at standing hip height
(~1.07 in these units) with nothing lowering it to a kneeling stance.

**Fix: an OBJECT-level Z translation, `arm_obj.location = (0,0,-drop)`.**
Same category of move as the supine roll being an object-level rotation
rather than a pose-bone one — anything that needs to change the RIG'S
overall position/orientation in world space, rather than a limb's pose
relative to its parent, belongs on the object, not a bone. `drop=0.55`
(found by probe + render, not derived) puts the knee at floor level with
`thigh` left near its standing rest angle. Landed in `_lib.py` as
`apply_quadruped_base()` / `run_quadruped()`, parallel to the supine
entry points — camera is a normal level azimuth shot (reusing
`camera_for_azimuth`) rather than top-down, since a quadruped figure reads
from the side like a standing one, just lower and horizontal.

**Getting the arm to reach the floor took several more iterations and
confirmed the seated-pose lesson generalizes: bounds-driven algebra is
unreliable this far into compound rotations.** The shoulder, after the
spine's forward pitch, is no longer directly above the hand the way it is
standing — an arm pitched by a rough estimate (-15°) left the wrist
44% of body-height off the ground. The angle is very sensitive because it
inherits the torso's already-large pitch: small forearm changes produced
large world-space swings once the upperarm was already near -70°. Settled
by iterating render + tail-position log together (not by computing it):
`upperarm` -68°, `forearm` +25° puts the hand at the floor for a planted
support arm.

**Thread the Needle's reach-under motion is a genuine approximation, not a
literal "hand slides through the gap."** The instructions describe the
arm sliding underneath the torso; three passes on the unrelated Standing
Reach-Through Twist already found that cross-midline arm adduction
collides with this torso mesh (documented earlier in this file), so the
same problem was expected here. What shipped instead: the reaching
`upperarm` swings to -140° (well past the support arm's -68°, deep
flexion) combined with a `chest`/`spine` twist (the already-proven
local-Y convention) so that shoulder visibly lowers and the head turns
down toward it — reads as "shoulder and ear toward the mat," the more
prominent part of the instructions, at the cost of the arm curling up
near the shoulder rather than extending out under the body. Shipped as
`right/left_thread_the_needle.py`, verified via `SupineExercisesUITests`
(renamed to cover 8 exercises now, all pass) — plays correctly in
`ExerciseMediaCard` with correct muscle-target chips.

**All originally-scoped Tier B rotation-audit exercises building on a new
base pose are now shipped**: supine (6) + quadruped (2) = 8. Cross-midline
arm adduction (Standing Reach-Through Twist) remains the one Tier A/B item
with authored-but-unshipped scripts, and arm-bone Y-twist (Sleeper Stretch,
Doorway External Rotation) and `hips` local-Y twist for anything other
than the windshield-wipers workaround remain fully untried.

## Related project context

- Body Map architecture / SceneKit loading: `Breath - Relax &
  Stretch/Views/BodyMap/BodySceneView.swift`; memory `bodymap-3d-skin-architecture`,
  `anatomy-model-replacement`.
- Blender export pipeline that produces the app OBJ: `Tools/blender/export_skin_muscle.py`
  (welds skin patches, bakes app-space coords, tags muscles). Run `graphify
  query "..."` for codebase questions (see project `CLAUDE.md`).
- Copyright/asset-sourcing: **`ASSET_CREDITS.md` (repo root) is now the
  authoritative record** — Z-Anatomy CC-BY-SA 4.0 over BodyParts3D CC-BY-SA
  2.1 Japan, the full author list, the modifications statement, and the note
  that **the rendered `.mp4` loops are themselves derivative works** carrying
  the same terms. Two things settled there: CC-BY-SA *permits commercial use*
  (the old "share-alike concern for a paid app" framing was misplaced — the
  real obligations are attribution + share-alike on the assets), and none of
  Z-Anatomy's NonCommercial-licensed reference models (inner ear, kidney) are
  in this app's mesh, which was verified against `skinmuscle_node_names.json`
  (269 nodes, layers = skin/muscle only). Broader video-sourcing analysis:
  `docs/superpowers/plans/2026-07-12-exercise-video-animation.md`.
