"""Left Standing Crescent Moon Side Stretch — muscle-body + skin-head animation.

Batch 15 (session push toward 130 exercises). "Raise both arms overhead,
clasp your left wrist, lean your torso to the right." Mechanically the
same shape as the already-shipped left_standing_side_reach.py (a
LEFT-named stretch bending the torso right, same spine/chest local-Z
sign), generalized to BOTH arms overhead instead of one (the clasping-hand
detail isn't animated — no hand-target IK).

Highlight: Left Obliques + Left Lats, matching the exercise's tags.
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
EXERCISE = "left_standing_crescent_moon_side_stretch"
VIDEO_NAME = "left_standing_crescent_moon_side_stretch.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left oblique", "left lats")

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(12)),
        "chest": (0, 0, r(10)),
        "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
    },
    60: {
        "spine": (0, 0, r(26)),
        "chest": (0, 0, r(20)),
        "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0),
    },
    90: {
        "spine": (0, 0, r(26)),
        "chest": (0, 0, r(20)),
        "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0),
    },
    120: {},
}

L.run(globals())
