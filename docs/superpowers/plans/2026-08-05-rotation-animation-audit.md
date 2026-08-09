# Rotation animation audit & plan

Scope: (1) audit the 14 shipped Blender muscle-animations for missing
rotations their exercise actually requires, (2) classify every unanimated
exercise whose movement is a rotation/twist, by whether the rig can
represent it today, and (3) lay out what to build next and in what order.
No code changes in this doc — pure research + plan, per
`Tools/blender/exercises/ANIMATION_HANDOFF.md`'s own methodology (numeric
probes before trusting a new axis convention, visual eyeballing for twist
correctness since twist barely moves a bone's tail position).

Source data pulled directly from `SeedData.json` (217 exercises),
`Tools/blender/exercises/_lib.py` (`build_armature`/`build_figure`, the
authoritative rig), `Tools/blender/exercises/ANIMATION_HANDOFF.md`, and all
14 shipped `Tools/blender/exercises/*.py` pose scripts.

---

## 1. What the rig can rotate today

12 bones: `hips → spine → chest → head`, `chest → upperarm.{L,R} →
forearm.{L,R}`, `hips → thigh.{L,R} → shin.{L,R}`.

**No wrist/hand/finger bone, no ankle/foot/toe bone, no separate neck bone**
(hands/feet are non-bone convex-hull "mitt" meshes weighted to
forearm/shin; the neck is just the base of the `head` bone). This is a hard
ceiling on what's representable — anything whose primary motion is a wrist,
finger, ankle, toe, or eye rotation cannot be animated without extending the
rig with new bones, which is out of scope here.

Two proven axis conventions, with a documented trap (signs don't transfer
between them):

| Bone group | Axis | Meaning |
|---|---|---|
| `upperarm.{L,R}`, `forearm.{L,R}` (hang down, local Y = world −Z) | local X | +X = swing back/behind (shoulder extension), −X = forward. Forearm: −X flexes the elbow. |
| same | local Z | +Z = adduct toward midline (left arm), mirror sign for right |
| same | local Y | twist along the bone's own long axis — **never used in any shipped exercise** |
| `head`, `chest`, `spine` (point up, local Y = world +Z) | local X | +X = forward pitch (opposite sign meaning from the arm bones — do not reuse that intuition) |
| same | local Z | +Z bends the bone toward the subject's own right |
| same | local Y | twist — proven, used only by the two seated-spinal-twist exercises |

`hips`, `thigh.{L,R}`, `shin.{L,R}` exist in the armature and are mapped to
muscle groups. **Update (2026-08-07): a static seated leg pose is now
proven** — `thigh.{L,R}` local-X = -90° (hip flexion forward to horizontal),
`shin.{L,R}` local-X = +90° (knee fold, note the opposite sign from thigh —
it's relative to the thigh's already-rotated frame), held constant across
every keyframe. Validated by probe and shipped on both Seated Spinal Twist
exercises (Finding 3 above). Full derivation in
`Tools/blender/exercises/ANIMATION_HANDOFF.md`'s "Rotation audit" section.
**This only covers a static held pose** — nothing that moves the legs mid-
clip (a lunge, a circle, a swing) has been validated; those still need their
own numeric-probe experiment before batch-authoring (see Tier C below).

---

## 2. Audit of the 14 shipped animations

| # | Exercise | Uses twist (Y)? | Verdict |
|---|---|---|---|
| 1 | Clasped-Hands Behind-Back Stretch | no | OK — no twist required by the movement |
| 2 | Neck Flexion (Chin-to-Chest) | no | OK |
| 3 | Standing Forward Fold (Ragdoll) | no | OK |
| 4 | Left Standing Side Bend | no | OK |
| 5 | Neck Extension (Look Up) | no | OK |
| 6 | Chin Tuck (Forward Head Reset) | no | OK |
| 7 | Right Standing Side Bend | no | OK |
| 8 | Standing Back Extension | no | OK |
| 9 | Cobra Stretch (Prone Press-Up) | no | OK |
| 10 | Left Seated Spinal Twist | **yes** | Was standing (no seated pose existed); **fixed 2026-08-07, see Finding 3** |
| 11 | Right Seated Spinal Twist | **yes** | Same — **fixed 2026-08-07** |
| 12 | Reverse Prayer Stretch | no | **Gap, but not fixable** — see below (now flagged `animationIsApproximate` in the app so this is disclosed to users) |
| 13 | Left Wall Bicep Stretch | no | **Gap — fixed 2026-08-07, see Finding 1** |
| 14 | Right Wall Bicep Stretch | no | **Gap — fixed 2026-08-07, see Finding 1** |

### Finding 1 (fixed 2026-08-07): Wall Bicep Stretch (L/R) was missing its torso rotation

Instructions: *"Slowly rotate your torso away from the wall until you feel a
stretch through the front of your left arm."* The shipped `POSES` only pitched
`upperarm.L`/`.R` (0°→20°→45° on X) and flexed the forearm slightly — there
was no `chest`/`spine` local-Y twist keyframe at all, even though that's the
actual named motion. Fixed by adding a shallow `chest`/`spine` twist (8-15°,
reusing the seated-spinal-twist sign convention: positive Y = twist right)
alongside the existing arm pitch. Re-rendered, re-encoded, verified visually
(extra far-side silhouette now visible past the profile line) and in the
running app.

### Finding 3 (fixed 2026-08-07): Seated Spinal Twist (L/R) wasn't actually seated

The rig had no proven pose-authoring convention for `thigh`/`shin`, so these
exercises rendered as a *standing* torso rotation despite being named
"seated" — the original script docstring said as much. Validated a static
seated leg pose via a throwaway probe (`thigh.{L,R}` local-X = -90°,
`shin.{L,R}` local-X = +90°, held constant across every keyframe) — see
`Tools/blender/exercises/ANIMATION_HANDOFF.md`'s "Rotation audit" section
for the full derivation. Applied to both scripts, re-rendered, re-encoded.
This convention only covers a *static held* seated pose, not a dynamic leg
movement — Tier C below is still blocked for anything that moves the legs
mid-clip.

### Finding 2 (documented limitation, no fix possible): Reverse Prayer Stretch's wrist rotation

Instructions: *"Rotate your wrists so your palms come together."* The rig
has no wrist bone (§1), so this is not fixable without a rig extension. The
shipped animation's forearm-pitch approximation is a reasonable stand-in
given that ceiling — recommend leaving as-is and not treating this as a bug.

---

## 3. Unanimated exercises whose movement is a rotation/twist

Filtered from all 217 exercises down to genuine rotation-primary movements
(excluded false positives like "roll up slowly" transition cues, "turned"
foot-placement setup details, etc. that matched a rotation keyword but
aren't the exercise's actual motion).

### Tier A — proven conventions, ready to author now

Torso twist (`chest`/`spine` local-Y, same convention as the shipped seated
twists) combined with arm pitch/bend where needed:

| Exercise | Proposed bones/axes |
|---|---|
| Seated Spinal Rotation with Overhead Reach (L/R) | `spine`/`chest` Y-twist (reuse seated-twist angles) + `upperarm` reaching overhead + the now-proven static seated leg pose (thigh -90/shin +90) |
| Left/Right Thread the Needle | `spine`/`chest` Y-twist (large, ~35-45°) + `upperarm` reaching under |
| Left/Right Supine Chest Opener (Open Book) | `spine`/`chest` Y-twist + `upperarm` opening out to the side; new camera azimuth (lying pose) |
| Left/Right Doorway Bicep Stretch | `spine`/`chest` Y-twist + `upperarm` pitch (shares the Wall Bicep Stretch fix above) |
| Left/Right Wall Corner Pec Stretch | `spine`/`chest` Y-twist + `forearm` pinned pitch |
| Left/Right Standing Reach-Through Twist | `spine`/`chest` Y-twist (larger range) + `upperarm` reaching down-and-across |

Head rotation (`head` local-Y twist, proven) alone or combined with the
already-proven X (pitch) / Z (side-bend) axes:

| Exercise | Proposed bones/axes |
|---|---|
| Seated Neck Rotation | `head` Y-twist only (turn to look over each shoulder) |
| Left/Right Chin-to-Shoulder Diagonal Stretch | `head` X (nod down) + Y (turn) combined — individually proven, untested together |
| Left/Right Scalene Neck Stretch | `head` Z (side tilt) + Y (slight rotate) combined — same caveat |
| Seated Neck Rolls | `head` circular path through 4-8 keyframes combining X+Z (all proven axes, just more keyframes to trace a circle) |

### Tier B — needs one new axis-convention experiment first

These are representable in principle with existing bones, but require
validating an axis usage that's never been tried, via the same
numeric-probe-then-eyeball process used for every prior convention:

| Exercise | What's new | Notes |
|---|---|---|
| Left/Right Sleeper Stretch (Internal Rotation) | `upperarm` **local-Y twist** (shoulder internal rotation) | Y-twist has only ever been used on the vertical bones (spine/chest); untested on an arm bone. Needs its own probe before trusting sign/degree. |
| Left/Right Doorway External Rotation Stretch | same — `upperarm` Y-twist, opposite direction | |
| Left/Right Supine Spinal Twist (Windshield Wipers) | `hips` local-Y twist | The twist here is driven by the lower body (knees falling to one side, shoulders pinned), not upper-torso twist like the seated version — needs `hips` bone twist, structurally analogous to the proven `spine`/`chest` convention but never tried on `hips`. |
| Shoulder Roll | `upperarm` circular path combining X+Z+Y | Real shoulder rolls involve scapular elevation the rig can't represent (no scapula bone); this would be an approximation via the upperarm alone — medium confidence, validate visually before committing. |

### Tier C — blocked on hip/thigh/shin convention research

None of these can be authored until someone runs a probe experiment on
`hips`/`thigh.{L,R}`/`shin.{L,R}` (documented as having no proven convention
at all — a bigger, standalone research task, not a per-exercise tweak):

| Exercise | What's needed |
|---|---|
| Standing Hip Circles | `hips` circular motion |
| Runner's Lunge with Rotation (L/R) | `thigh` lunge pitch (leg) + `spine`/`chest` twist (torso, already Tier A on its own) |
| World's Greatest Stretch (L/R) *(the exercise I added in the previous session)* | same split: `thigh` lunge pitch blocked, torso twist/reach is Tier A |
| Dynamic Standing Leg Swings | `thigh` pendulum swing (sagittal pitch, not twist, but same "no proven convention" blocker) |
| Left/Right Cossack Squat Stretch | `thigh` lateral shift/rotation |

**Interim option for the two torso+lunge exercises** (Runner's Lunge with
Rotation, World's Greatest Stretch): ship a simplified first pass that
animates only the torso twist/reach and leaves the legs in the rig's static
rest stance — the same trick `standing_forward_fold_ragdoll.py` already uses
(it never touches `hips`/`thigh`, the fold reads entirely through
spine+chest+upperarm). Less anatomically exact, but doesn't block on the
Tier C research and reuses only proven axes.

### Tier D — not representable with the current rig; recommend skipping

No bone exists for the joint doing the actual moving. Recommend leaving
these as text-only (no animation), not attempting an approximation:

| Exercise | Blocked by |
|---|---|
| Wrist Circles | no wrist bone |
| Wrist & Forearm Release | no wrist bone |
| Left/Right Extended-Fingers Bicep Stretch | wrist-extension detail, no wrist bone |
| Gentle Eye Rolls | no eye bone/blend-shape — the rig is skeletal, not a facial rig |
| Temporalis Release | finger self-massage circles, no per-finger articulation |

---

## 4. Recommended order

1. **Fix Finding 1** (Wall Bicep Stretch L/R torso twist) — small, isolated,
   corrects two exercises already in the app.
2. **Tier A batch** (10 exercises) — all proven conventions, same risk
   profile as the third batch that already shipped. Straightforward: author
   scripts, run Blender headless, eyeball renders, encode, wire into
   `SeedData.json` + bundle (the `migrateV9` insert-missing migration added
   in the previous session means these reach already-seeded devices
   automatically once `animationName` is set).
3. **Tier B experiments** (3 new axis conventions: arm-bone Y-twist,
   `hips` Y-twist, compound shoulder-roll path) — one throwaway numeric
   probe per convention before trusting it, per the handoff doc's own
   process. Once validated, author the associated exercises.
4. **Tier C research spike** (hip/thigh/shin convention) — separate,
   larger effort; only start once Tier A/B are shipped. Until then, ship
   the simplified torso-only versions of Runner's Lunge with Rotation and
   World's Greatest Stretch if desired.
5. **Tier D** — no action; these stay text-only unless the rig itself gets
   extended with wrist/finger/eye bones (a much bigger, separate project,
   not recommended right now given how few exercises need it).

## 5. Per-exercise process (unchanged from the existing pipeline)

1. Author a ~50-line `Tools/blender/exercises/<name>.py` script (`EXERCISE`,
   `VIDEO_NAME`, `CAMERA_AZIMUTH`, `WORKED_KEYWORDS`, `POSES`, call
   `L.run(globals())`).
2. Run headless: `/Applications/Blender.app/Contents/MacOS/Blender -b
   --python "Tools/blender/exercises/<name>.py"`.
3. Encode the rendered PNG frame sequence: `swift
   Tools/blender/encode_mp4.swift <framesDir> <out>.mp4 30 <w> <h>`.
4. Add the mp4 to the Xcode bundle (drop in the synced Animations folder).
5. Set `animationName` on the exercise's `SeedData.json` entry.
6. `graphify update .`, run `SeedDataTests`/`SeedMigratorTests`, verify in
   simulator (existing `verify` skill covers the XCUITest-driven flow).
