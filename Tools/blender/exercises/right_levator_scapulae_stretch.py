"""Right Levator Scapulae Stretch — muscle-body + skin-head animation.

Mirror of left_levator_scapulae_stretch.py — see that script's docstring for
the full derivation. Instructions here: "turn your head about 45 degrees to
the LEFT... look down toward your left armpit" — turning left = +Y (see the
left script's docstring for the numeric probe that pins this sign; +Y = the
subject's own left, the same convention the chest/spine twist family uses).
Tuck (+X) unchanged since it's not a sided motion.

**Sign bug found and fixed (2026-08-22, animation-vs-instructions audit,
same pass as the arm-to-head fix below):** this script's own docstring
above has always correctly stated the turn should be +Y, but the `POSES`
dict below shipped with the SAME -Y values as the left script, unmirrored —
a copy-paste-and-never-updated bug, not a wrong sign belief (contrast the
"Twist direction" bug elsewhere in ANIMATION_HANDOFF.md, which was a wrong
belief applied consistently). Caught by literally comparing this file's
POSES against left_levator_scapulae_stretch.py's while adding the arm
fix — the two dicts were byte-for-byte identical, which is only correct
for the unsided `head` X pitch, not the sided Y turn. Fixed by flipping
the Y sign to positive.

Highlight: Back Neck + Right Trapezius (the side being stretched).
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
EXERCISE = "right_levator_scapulae_stretch"
VIDEO_NAME = "right_levator_scapulae_stretch.mp4"

CAMERA_AZIMUTH = 315

WORKED_KEYWORDS = ("back neck", "right trapezius")

# Opposite-side arm (left hand rests on top of the head) — mirror of the
# left script's numeric fit (flip local-Z sign on upperarm.L/forearm.L).
_ARM_UP = {"upperarm.L": (r(-130), 0, r(-30)), "forearm.L": (r(-100), 0, r(30))}
_ARM_MID = {"upperarm.L": (r(-80), 0, r(-18)), "forearm.L": (r(-60), 0, r(18))}

POSES = {
    0: {},
    30: {**_ARM_MID, "head": (r(8), r(25), 0)},
    60: {**_ARM_UP, "head": (r(14), r(45), 0)},
    90: {**_ARM_UP, "head": (r(14), r(45), 0)},
    120: {},
}

L.run(globals())
