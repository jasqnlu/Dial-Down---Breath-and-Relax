"""Right Isometric Neck Side Press — mirror of the left version.

See left_isometric_neck_side_press.py's docstring.
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
EXERCISE = "right_isometric_neck_side_press"
VIDEO_NAME = "right_isometric_neck_side_press.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right trapezius", "front neck")

POSES = {
    0:   {},
    30:  {"head": (0, 0, r(4))},
    60:  {"head": (0, 0, r(7))},
    90:  {"head": (0, 0, r(4))},
    120: {},
}

L.run(globals())
