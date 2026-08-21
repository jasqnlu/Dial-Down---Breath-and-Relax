"""Right Cross-Body Rear Delt Stretch — mirror of the left version.

See left_cross_body_rear_delt_stretch.py's docstring. Per Gotcha #6, the
RIGHT arm's adduction sign is the mirror of the left's (-Z instead of +Z).
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
EXERCISE = "right_cross_body_rear_delt_stretch"
VIDEO_NAME = "right_cross_body_rear_delt_stretch.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right shoulder",)

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-40), 0, r(-20))},
    60:  {"upperarm.R": (r(-75), 0, r(-35))},
    90:  {"upperarm.R": (r(-75), 0, r(-35))},
    120: {},
}

L.run(globals())
