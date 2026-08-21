"""Standing IT Band Side Stretch (Right) — mirror of the left version.

See standing_it_band_side_stretch_left.py's docstring.
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
EXERCISE = "standing_it_band_side_stretch_right"
VIDEO_NAME = "standing_it_band_side_stretch_right.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right quadricep", "right hip flexor")

_CROSS = {"thigh.R": (r(8), 0, r(-10))}

POSES = {
    0: {**_CROSS},
    30: {
        **_CROSS,
        "spine": (0, 0, r(-12)),
        "chest": (0, 0, r(-10)),
        "upperarm.R": (r(-70), 0, 0),
    },
    60: {
        **_CROSS,
        "spine": (0, 0, r(-26)),
        "chest": (0, 0, r(-20)),
        "head": (0, 0, r(-6)),
        "upperarm.R": (r(-150), 0, 0),
    },
    90: {
        **_CROSS,
        "spine": (0, 0, r(-26)),
        "chest": (0, 0, r(-20)),
        "head": (0, 0, r(-6)),
        "upperarm.R": (r(-150), 0, 0),
    },
    120: {**_CROSS},
}

L.run(globals())
