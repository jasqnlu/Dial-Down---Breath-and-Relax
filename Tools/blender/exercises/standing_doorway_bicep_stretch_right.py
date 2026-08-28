"""Standing Doorway Bicep Stretch (Right) — mirror of the left version.

See standing_doorway_bicep_stretch_left.py's docstring.
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
EXERCISE = "standing_doorway_bicep_stretch_right"
VIDEO_NAME = "standing_doorway_bicep_stretch_right.mp4"

CAMERA_AZIMUTH = 270

WORKED_KEYWORDS = ("right bicep",)

POSES = {
    0: {},
    30: {
        "upperarm.R": (r(22), 0, 0),
        "chest": (0, r(8), 0),
    },
    60: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(16), 0),
        "spine": (0, r(9), 0),
    },
    90: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(16), 0),
        "spine": (0, r(9), 0),
    },
    120: {},
}

L.run(globals())
