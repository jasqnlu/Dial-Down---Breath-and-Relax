"""Frog Rock (Kneeling Glute Mobility Flow) — muscle-body + skin-head animation.

Retry (2026-08-27) of a composition dropped in the 31-exercise batch for a
badly-framed peak camera (figure cropped to an unrecognizable diagonal
sliver) despite a clean render log — the pose itself was never the problem,
only the camera choice. Rebuilt from scratch (the dropped attempt's script
wasn't kept) reusing `childs_pose.py`'s proven quadruped-fold shape and its
exact `CAMERA_AZIMUTH = 90` side view, rather than re-deriving a new camera
angle — the instructions describe "rock hips backward toward heels, then
forward again," the same sagittal-plane fold `childs_pose` already animates
cleanly from the side. The one addition on top of that proven fold: thighs
held constant in abduction ("widen your knees out to the sides") — a
coronal-plane offset, which a SIDE camera views edge-on and so doesn't
disturb the framing that already works for the fold itself (same "the
static part of a pose can be foreshortened, only the ANIMATED part must
stay visible" reasoning documented elsewhere in this batch).

Shallower fold than child's pose (a repeating rock, not a held deep fold) —
peak frame keeps the rock modest per "gentle rocking" in the instructions.

Second bug found in THIS retry: the first attempt added thigh abduction
(local Z) on top of the proven quadruped thigh's existing local-X lean to
approximate "widen your knees out to the sides," and rendered as a broken
diagonal X-splayed figure — composing a second Euler axis onto an
already-rotated bone doesn't isolate a clean "spread" the way it would from
a rest pose (the same class of non-commuting-rotation trap
`apply_supine_base`'s docstring already warns about for its own roll
component, hit here on a different bone). Dropped the knee-widening detail
entirely rather than debug the correct compound rotation — the rocking
motion (the animated, muscle-relevant part) is what the highlight targets;
the static stance width is a cosmetic approximation loss.

Third bug found in THIS retry, after dropping abduction: still rendered
as a broken diagonal floating figure. Root cause: `_BASE` omitted
`apply_quadruped_base`'s own documented constant `spine: (r(95),0,0)` —
without it, `spine` defaults to 0 rotation (upright torso) while the legs
are folded for quadruped and the whole rig is Z-dropped, so the torso
stayed vertical while pinned to a horizontally-folded pelvis, reading as a
figure flung diagonally in midair. Every `run_quadruped` script needs its
own copy of that full constant set in `_BASE` (spine/chest/thigh/shin/
head/upperarm/forearm) — it is not implied by `apply_quadruped_base`
itself, which only performs the object-level Z translation, not the
per-bone pose.
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
EXERCISE = "frog_rock_kneeling_glute_mobility_flow"
VIDEO_NAME = "frog_rock_kneeling_glute_mobility_flow.mp4"

CAMERA_AZIMUTH = 30

WORKED_KEYWORDS = ("glute",)

# Standard quadruped support fold (apply_quadruped_base's full documented
# constant set) — the knee-widening detail was dropped, see docstring's
# second-bug note.
_BASE = {
    "spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": (r(-10), 0, 0),
    "thigh.L": (r(5), 0, 0), "shin.L": (r(100), 0, 0),
    "thigh.R": (r(5), 0, 0), "shin.R": (r(100), 0, 0),
    "upperarm.L": (r(-68), 0, 0), "forearm.L": (r(25), 0, 0),
    "upperarm.R": (r(-68), 0, 0), "forearm.R": (r(25), 0, 0),
}

# Rocking motion: hips shift backward toward the heels and forward again —
# approximated as a modest deepening of the spine/head fold from the
# neutral quadruped base (a small step toward child's-pose territory,
# nowhere near as deep — "gentle rocking," not a full sit-back).
POSES = {
    0:   {**_BASE},
    60:  {**_BASE, "spine": (r(105), 0, 0), "head": (r(-2), 0, 0)},
    120: {**_BASE},
}

L.run_quadruped(globals())
