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
| same | local Y | twist. **−Y = subject's own right, +Y = subject's own LEFT.** Widely used (both seated twists, both wall/doorway bicep stretches, wall corner pec, overhead reach, head rotation). |

> **⚠️ Twist sign corrected 2026-08-08.** This table originally said `+Y`
> twists toward the subject's *right*. It is the opposite, and four shipped
> animations rotated backwards as a result. See "Finding 4" in §3b for the
> probe that settled it. Anything below written before that date that implies
> `+Y = right` is wrong.

Also note (2026-08-08): **prefer `local-X` (flexion) to `local-Z` (abduction)
on arm bones.** The source mesh is arms-down, so abduction drags a sheet of
torso geometry outward — 85° tore the pec, 155° tore the lat. The same poses
authored as forward flexion (to −150°) render cleanly.

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
| 10 | Left Seated Spinal Twist | **yes** | Was standing (no seated pose existed); fixed 2026-08-07 (Finding 3). **Twisted the wrong way; re-fixed 2026-08-08 (Finding 4)** |
| 11 | Right Seated Spinal Twist | **yes** | Same — fixed 2026-08-07, **re-fixed 2026-08-08 (Finding 4)** |
| 12 | Reverse Prayer Stretch | no | **Gap, but not fixable** — see below (now flagged `animationIsApproximate` in the app so this is disclosed to users) |
| 13 | Left Wall Bicep Stretch | no | Gap — fixed 2026-08-07 (Finding 1). **Twisted the wrong way; re-fixed 2026-08-08 (Finding 4)** |
| 14 | Right Wall Bicep Stretch | no | Same — fixed 2026-08-07, **re-fixed 2026-08-08 (Finding 4)** |

### Finding 1 (fixed 2026-08-07): Wall Bicep Stretch (L/R) was missing its torso rotation

Instructions: *"Slowly rotate your torso away from the wall until you feel a
stretch through the front of your left arm."* The shipped `POSES` only pitched
`upperarm.L`/`.R` (0°→20°→45° on X) and flexed the forearm slightly — there
was no `chest`/`spine` local-Y twist keyframe at all, even though that's the
actual named motion. Fixed by adding a shallow `chest`/`spine` twist (8-15°)
alongside the existing arm pitch. Re-rendered, re-encoded, verified visually
(extra far-side silhouette now visible past the profile line) and in the
running app.

> **⚠️ This fix twisted the wrong way and was itself corrected 2026-08-08.**
> It reused the seated-spinal-twist convention believing positive Y = twist
> right; positive Y is *left*, so the torso rotated toward the wall rather
> than away from it. Signs are now negative. See Finding 4 in §3b.

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

### Tier A — ✅ DONE 2026-08-08 (12 shipped, 6 reclassified)

Was "proven conventions, ready to author now", and counted as 10 exercises —
both wrong. It was **18** exercises (the count read table rows, but most rows
are L/R pairs), and 3 of the rows turned out not to be Tier A at all. Outcome
and findings in §3b.

Torso twist (`chest`/`spine` local-Y) combined with arm pitch/bend:

| Exercise | Status |
|---|---|
| Seated Spinal Rotation with Overhead Reach (L/R) | ✅ shipped — but via `upperarm` local-X **flexion**, not the abduction originally proposed; abduction tore the lat |
| Left/Right Doorway Bicep Stretch | ✅ shipped |
| Left/Right Wall Corner Pec Stretch | ✅ shipped — abduction reduced and made flexion-dominant to stop the pec tearing |
| Left/Right Thread the Needle | ❌ **not Tier A** → Tier B. Starts on hands and knees; no quadruped pose convention exists |
| Left/Right Supine Chest Opener (Open Book) | ❌ **not Tier A** → Tier B. Lying; the plan flagged "new camera azimuth (lying pose)" without noting the *pose* is unproven |
| Left/Right Standing Reach-Through Twist | ❌ **authored but not shipped** → Tier B. Three passes could not make the cross-body reach read; adduction past the midline collides with the arms-down torso. Scripts kept, with the failure documented in their docstrings |

Head rotation (`head` local-Y twist) alone or combined with X (pitch) /
Z (side-bend):

| Exercise | Status |
|---|---|
| Seated Neck Rotation | ✅ shipped — both directions in one clip, needs `PEAK_FRAME` override |
| Left/Right Chin-to-Shoulder Diagonal Stretch | ✅ shipped — X+Y combination worked |
| Left/Right Scalene Neck Stretch | ✅ shipped — first three-axis pose (X+Y+Z) |
| Seated Neck Rolls | ✅ shipped — 9-keyframe circular path |

All four render **standing**, not seated: the seated leg pose only reads from
azimuth 45+, which conflicts with the camera angles that make head motion
legible, and sitting is incidental to a neck stretch. This also matches the
three neck animations already shipped.

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
| Left/Right Thread the Needle *(moved from Tier A, 2026-08-08)* | **quadruped / hands-and-knees base pose** | The torso twist is proven; the base position is not. Nothing in the rig has ever been posed on all fours. |
| Left/Right Supine Chest Opener (Open Book) *(moved from Tier A, 2026-08-08)* | **side-lying base pose** — see 2026-08-09 update below; this one isn't actually flat-on-the-back | Instructions say "lie on your **side**", not on the back — mis-scoped under "supine" originally. |
| Left/Right Standing Reach-Through Twist *(moved from Tier A, 2026-08-08)* | **cross-midline arm adduction** | Scripts already authored — only the reach fails to read. Adduction past the body's centre line collides with the torso because the source mesh is arms-down with no clearance. |

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

---

## 3b. Execution outcome (2026-08-08)

**Shipped 12 exercises; 26 of 217 now have animations (was 14).**
`seated_neck_rotation`, `seated_neck_rolls`,
`left/right_chin_to_shoulder_diagonal_stretch`,
`left/right_scalene_neck_stretch`, `left/right_doorway_bicep_stretch`,
`left/right_wall_corner_pec_stretch`,
`seated_spinal_rotation_overhead_reach_left/right`.

### Finding 4 (found during execution): every shipped twist rotated BACKWARDS

The biggest result of this batch is a correction, not a new animation. §1's
table says `+Y` twists toward the subject's right. **It is the opposite.**
A numeric probe on the shoulder position (`_twist_probe.py`; a twisting bone
barely moves its own tail, so the usual sanity log is blind here) showed
`chest +Y` swings the LEFT shoulder backward — a rotation toward the
subject's own **left**.

That invalidated all four shipped twist animations, including both fixes this
plan itself recommended in §4.1:

| Exercise | Instructions | Was doing | Fixed |
|---|---|---|---|
| Left Seated Spinal Twist | "twist to the right" | twisting left | ✅ |
| Right Seated Spinal Twist | "twist to the left" | twisting right | ✅ |
| Left Wall Bicep Stretch | rotate away from left-side wall | twisting left | ✅ |
| Right Wall Bicep Stretch | rotate away from right-side wall | twisting right | ✅ |

Root cause of the error surviving three batches: the twist exercises were
verified by confirming the L/R renders were *mirrored*, which proves symmetry
but not direction — two backwards animations mirror perfectly. **Verify one
side's absolute direction against the written instructions, then mirror.**

### Tier A was over-classified — 6 of its 18 exercises are not Tier A

§3 says "Tier A batch (10 exercises)", counting table rows; most rows are L/R
pairs, so Tier A was really **18 exercises**. Of those, 6 are blocked on a
base body position the rig has never represented, and are moved to Tier B:

| Exercise | Why it isn't Tier A |
|---|---|
| Left/Right Thread the Needle | starts **on hands and knees** — no quadruped convention. Faking it as a standing twist would duplicate Standing Reach-Through Twist. |
| Left/Right Supine Chest Opener (Open Book) | **lying** — no supine convention (the plan already flagged "new camera azimuth (lying pose)" without noting the pose itself is unproven) |
| Left/Right Standing Reach-Through Twist | scripts authored and kept but NOT shipped — three passes could not make the cross-body reach read; adduction past the midline collides with the arms-down torso |

### Other findings worth carrying forward

- **Prefer `local-X` (flexion) to `local-Z` (abduction) on arm bones.** 85° of
  abduction tore the pec into a sheet; 155° tore the lat into a cape. The same
  poses re-authored as forward flexion (up to −150°) render cleanly, and
  flexion is the anatomically correct path for an overhead reach anyway.
- **A proven pose can still render as garbage at the wrong camera azimuth.**
  The seated leg pose only reads from azimuth 45+; near azimuth 0 the camera
  looks straight down the thigh and it collapses. The neck family therefore
  ships standing.
- **Read instructions, not names, for direction.** `Left Standing Side Bend`
  names the side stretched; `Seated Spinal Rotation (Left)` names the
  direction. Four exercises here would have shipped backwards otherwise.
- **Licensing:** added `ASSET_CREDITS.md` recording the Z-Anatomy CC BY-SA 4.0
  provenance. The `.mp4` loops are renderings of that mesh and so are
  derivative works carrying the same terms — easy to overlook since they
  contain no mesh data. A code `LICENSE` file is still outstanding.

---

## 4. Recommended order

1. ~~**Fix Finding 1** (Wall Bicep Stretch L/R torso twist)~~ — ✅ done
   2026-08-07, then **re-fixed 2026-08-08** when the twist direction it
   relied on turned out to be documented backwards (Finding 4).
2. ~~**Tier A batch**~~ — ✅ done 2026-08-08. 12 of 18 shipped; 6 moved to
   Tier B (see §3). 26 of 217 exercises now animated.

**Next up:**

3. **Tier B experiments** — now **6 conventions**, not 3. The original
   three (arm-bone Y-twist for the Sleeper/External Rotation stretches,
   `hips` Y-twist for the Supine Spinal Twists, compound shoulder-roll
   path), plus three inherited from Tier A:
   - **quadruped / hands-and-knees pose** → unblocks Thread the Needle (L/R)
   - **supine / lying pose** → unblocks Supine Chest Opener (L/R), and would
     also serve the Supine Spinal Twists and Supine Figure-4 stretches
   - **cross-midline arm adduction** → unblocks Standing Reach-Through Twist
     (L/R), whose scripts are already written and only need the reach to read

   One throwaway numeric probe per convention before trusting it, per the
   handoff doc's process — and per Finding 4, verify each one's *absolute*
   direction against an exercise's written instructions, not just that the
   L/R pair mirror each other.
4. **Tier C research spike** (dynamic hip/thigh/shin motion) — unchanged.
   Note the *static* seated pose is now proven and shipped; what remains
   unproven is anything that moves the legs mid-clip. Until then, the
   simplified torso-only versions of Runner's Lunge with Rotation and
   World's Greatest Stretch are still available if wanted.
5. **Tier D** — no action; these stay text-only unless the rig itself gets
   extended with wrist/finger/eye bones (a much bigger, separate project,
   not recommended right now given how few exercises need it).

## 3c. Supine probe outcome (2026-08-09, two passes)

Ran the highest-value Tier B experiment (flat-on-the-back base pose), then a
follow-up pass that fixed 2 of the 3 exercise families it initially couldn't
unblock. Full derivation in `Tools/blender/exercises/ANIMATION_HANDOFF.md`'s
"Supine pose probe" section — summary:

- **Proven and documented:** `hips` local-X = −90° (constant) tips the whole
  rig to lying flat, face-up. Top-down camera reads cleanly, matches the
  app's portrait clip aspect. This is the base convention for all supine
  work, landed in `_lib.py` as `apply_supine_base()` / `run_supine()`.
- **Shipped (4 of 6), first pass failed but a different technique worked:**
  - Supine Chest Opener (L/R) is actually **side-lying**, not flat-on-back
    (instructions say "lie on your side") — a plan mis-scope caught this
    round. First pass tried a second `hips` pose-bone Y-rotation to "roll"
    onto the side; that failed (body just re-spun flat in the horizontal
    plane). Second pass rolled the ARMATURE OBJECT itself around world Y
    instead of the bone — object-level rotation composes in true world
    space, unlike stacking a second Euler angle on an already-rotated bone.
    Worked on the first retry, shipped as `right/left_supine_chest_opener.py`.
  - Supine Spinal Twist (L/R) needs the knees to swing while shoulders stay
    planted. First pass tried counter-rotating `spine` against a `hips`
    twist (didn't cancel — probed numerically) and then a direct `thigh`
    swing at 25° (kept the torso fixed but tore geometry at the hip crease).
    Second pass reused the direct-`thigh`-swing approach at 10-20° instead
    of 25° — clean, no tearing (same lesson as the arm-abduction gotcha:
    angle-dependent, not axis-forbidden). Also dropped the literal 90°
    "arms in a T-shape" (reproduced known abduction tearing) for 45°.
    Shipped as `right/left_supine_spinal_twist.py`.
- **Still blocked, not reattempted:**
  - Supine Figure-4 (L/R) needs one shin to cross toward the opposite knee.
    The convex-hulled foot "mitt" stretches into thin webbing at the swing
    angle needed to actually reach — this is a bone-distance/joint-blend
    problem, not an angle-magnitude one, so "just use a smaller angle" (what
    fixed the spinal twist) doesn't apply here. Base bent-knee pose renders
    fine on its own; only the cross itself fails.

Net: 4 of 6 target exercises shipped, verified in the running app (not just
Blender renders) via `SupineExercisesUITests`. Supine Figure-4 remains open
for a future session.

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
