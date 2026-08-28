"""Right Isometric Neck Side Press — mirror of the left version.

See left_isometric_neck_side_press.py's docstring, including the
2026-08-22 arm-to-head fix. Mirror: same local-X, flipped local-Z on both
`upperarm.R`/`forearm.R`.
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

_ARM_UP = {"upperarm.R": (r(-115), 0, r(-10)), "forearm.R": (r(-150), 0, r(30))}
_ARM_MID = {"upperarm.R": (r(-70), 0, r(-6)), "forearm.R": (r(-90), 0, r(18))}

POSES = {
    0:   {},
    30:  {**_ARM_MID, "head": (0, 0, r(4))},
    60:  {**_ARM_UP, "head": (0, 0, r(7))},
    90:  {**_ARM_UP, "head": (0, 0, r(4))},
    120: {},
}

L.run(globals())
