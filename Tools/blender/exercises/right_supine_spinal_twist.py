"""Right Supine Spinal Twist (Windshield Wipers) — muscle-body + skin-head
animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Flat-on-the-back supine base (ROLL_DEG=0 — see ANIMATION_HANDOFF.md's
"Supine pose probe" section), no roll needed for this one. Instructions:
"Lie on your back... let both knees fall gently to the LEFT... turn your
head to look toward your RIGHT hand."

Motion: `thigh.{L,R}` local-Z swings the knees as a unit (kept small, 10deg —
25deg tore geometry at the hip crease in an earlier probe; 10-15deg reads
visibly without tearing). Sign confirmed by a numeric probe, not assumed:
`thigh` local-Z POSITIVE swings the knees toward the subject's own RIGHT
(shin.L world-x went from +0.105 to -0.024, shin.R from -0.105 to -0.234 —
both toward -X, and world +X is established as the subject's left elsewhere
in this doc, so -X = right). This exercise wants the LEFT direction, so
NEGATIVE. `head` local-Y reuses the already-proven twist convention
(+Y = subject's own left, -Y = own right) — that convention is defined
relative to the subject's own body, so it holds regardless of the supine
pitch. "Look toward RIGHT hand" = head local-Y negative.

Tried first: counter-rotating `spine` against a `hips` twist to keep the
shoulders visually still while only the hips/legs move. That does NOT
cancel (probed numerically — spine/chest/head tails moved substantially even
with the opposite sign on spine). This script sidesteps the problem
entirely by never touching `hips`/`spine` beyond the constant base pitch —
only the thigh bones move, so the torso is untouched by construction, not
by a cancellation trick.

Fix (2026-08-19, tearing): `thigh.{L,R}` local-X was `-90` (composed on top
of the `-90` base pitch already on `hips`), which folded the knees into an
unusually tight tuck and tore a visible hole at the hip crease — visible
in the top-down camera even at rest (frame 0), before any windshield-wiper
motion, so this was a base-pose bug, not the already-fixed swing-angle
tearing above. Confirmed by rendering the existing .blend at several angles: -90 tore;
-75, -60, -45 were all clean at rest. Picked -75 (closest to the original
-90, so the "knees bent" read stays as tucked as possible) and re-checked
it clean at the peak twist pose too, not just rest. Dropped the base fold
from -90 to -75.

Fix (2026-08-19, motion): the tearing fix above was only checked against
still frames (rest + peak), not the played-back motion — the first pass
shipped with the swing amplitude unchanged (peak 20deg / quarter 12deg,
already inconsistent with this docstring's own "kept small, 10deg" claim,
apparently drifted during the 2026-08-09 tearing fix and never reconciled).
Watching the actual clip (a 3x3 frame-grid sampled across all 4s, not just
one static pose) showed the whole leg swinging as a stiff rigid pendulum
out to the side and back — reads as a kick, not "knees fall gently."
Untucking the base fold from -90 to -75 (above) made this worse: the same
degrees now lever a longer, less-foreshortened effective leg length, so
the feet sweep further. Reduced the swing to peak 10deg / quarter 6deg —
matches what this docstring always claimed — and re-checked the full
frame-grid, not just the peak frame, before re-shipping.

Fix (2026-08-19, "still doesn't look good" / reads as standing): both fixes
above only ever changed the POSE, never questioned the CAMERA — reported a
third time because the shot itself was the remaining problem.
`camera_topdown` (a pure orthographic top-down view) is mathematically
IDENTICAL in silhouette to a front view of a STANDING figure — a real
geometric fact, not a lighting/pose issue, so no amount of pose tuning
could have fixed it. Switched to `L.camera_oblique_supine` (elevated,
pulled back beyond the feet, angled down — see its docstring in `_lib.py`
for the full tuning derivation, including why a flat colored floor plane
was tried and rejected first) for this ROLL_DEG=0 family specifically
(chest-opener/sleeper-stretch's ROLL_DEG!=0 already reads fine — the side
roll itself provides the depth cue an orthographic top-down shot lacks).
Also brought `_ARMS_T` in from a wide 45-degree horizontal T (itself a
"standing reference pose" visual cue, independent of camera angle, and the
term that was forcing the camera back the most) to 25 degrees. Verified
with the full frame-grid across the clip again, this time specifically
checking that the knee-swing motion stayed visible from the new angle (an
earlier wide-azimuth camera attempt looked more dramatically 3D but viewed
the swing nearly end-on, foreshortening the exercise's actual motion to
near-invisibility — traded one invisible-motion bug for another before
landing on a smaller azimuth that keeps both readable).

One more consequence of the camera change: the oblique angle looks INTO the
hip crease from the side, where the earlier -75 fold (clean from directly
overhead) showed a visible dark gap again — a different viewing angle
exposes a different part of the same under-covered seam. Re-ran the same
angle sweep against this camera: -75 tore, -60 had a faint sliver, -45 was
clean from both the new oblique view and the original top-down check.
Tightened the base fold again, -75 to -45.

Then a SEPARATE defect showed up at -45 under the oblique camera: not a
mesh gap this time (film_transparent PNGs and a Cycles/Eevee comparison
render both confirmed real, correctly-oriented front-facing geometry there
— not a hole, not backfaces), but a solid near-black blob at the inner
knee/hip. Ruled out lighting config (tried FLAT shading, several MATCAP
presets, `shadow_intensity` down to 0 — the blob persisted under all of
them except FLAT, which removes ALL directional shading including the
muscle definition the app needs). The EEVEE comparison still showed a
fainter version of the same dark patch, which is the tell: this is a real,
deep self-shadowing crevice in the geometry at this fold angle — Workbench
in this pipeline has no fill light, so the crease renders full black
instead of the soft gray a multi-light renderer would give it. Shallower
angles reduce the crevice itself: -45 (blob), -30/-25 (faint remnant),
-20 (clean). Loosened the base fold again, -45 to -20 — legs read as less
deeply tucked than earlier passes, a real trade-off against the "knees
bent" instruction, but every tighter angle tried reintroduced the blob.

Fix (2026-08-20, "make the legs 90 degrees like it's supposed to seem"):
-20 was clean but doesn't read as a real bent-knee position — asked to get
closer to an actual 90-degree fold. Revisited the ROOT weighting instead of
continuing to trade the angle down: `blend_weights`'s defaults
(BLEND_TOP_K=2, BLEND_POWER=4.0) were tuned against ordinary single-joint
folds, and this hip fold is a compound one (thigh local-X on top of the
-90 already on hips) that every other exercise's joints never attempt.
Swept BLEND_TOP_K/BLEND_POWER against a standalone copy of `_lib.py`
(candidates need a full rebuild from the OBJ, not just a re-pose of an
already-built .blend, since weights are baked once in `build_figure`):
top_k=3/power=1.5 (more candidate bones, gentler distance falloff) closed
nearly all of the -75 crease that top_k=2/power=4 left open, and also
looked meaningfully better than top_k=2/power=4 at a literal -90 — but -90
itself never fully closed even at top_k=4/power=1.5, so it's a real
geometric limit (very likely a modeling-time seam between the thigh and hip
meshes, not something a skinning-weight blend can paper over indefinitely),
not just a matter of throwing more blend at it.

Landed on: keep the wider blend (top_k=3/power=1.5, added as optional
`build_figure`/`blend_weights` params, defaulting to the old constants for
every other exercise — see `run_supine`'s docstring in `_lib.py`), and
re-tighten the fold from -20 back to -75 (not all the way to -90, which
still isn't clean even with the wider blend). This is the same -75 that
tore under the OLD default blend after the camera fix (see the fix above,
"reads as standing") — the difference this time is the weighting, not the
angle, which is why it can hold at -75 without the crease reopening.
"""
import sys
import os

REPO = "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
sys.path.insert(0, os.path.join(REPO, "Tools/blender/exercises"))
import _lib as L  # noqa: E402

r = L.r

APP_OBJ = os.path.join(REPO, "Breath - Relax & Stretch/Resources/Models3D/BodySkinMuscle.obj")
NODE_MAP = os.path.join(REPO, "Breath - Relax & Stretch/Resources/skinmuscle_node_names.json")
OUT_DIR = os.path.join(REPO, "Tools/blender/generated/exercises")
EXERCISE = "right_supine_spinal_twist"
VIDEO_NAME = "right_supine_spinal_twist.mp4"

ROLL_DEG = 0  # flat on the back, no side roll

WORKED_KEYWORDS = ("spinal erector", "lower back", "right obliques")

_ARMS_T = {
    "upperarm.L": (0, 0, r(-25)),
    "upperarm.R": (0, 0, r(25)),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, 0, 0), **_ARMS_T},
    30:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-75), 0, r(-6)), "thigh.R": (r(-75), 0, r(-6)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(-18), 0), **_ARMS_T},
    60:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-75), 0, r(-10)), "thigh.R": (r(-75), 0, r(-10)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(-35), 0), **_ARMS_T},
    90:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-75), 0, r(-6)), "thigh.R": (r(-75), 0, r(-6)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(-18), 0), **_ARMS_T},
    120: {"hips": (r(-90), 0, 0), "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, 0, 0), **_ARMS_T},
}

L.run_supine(globals())
