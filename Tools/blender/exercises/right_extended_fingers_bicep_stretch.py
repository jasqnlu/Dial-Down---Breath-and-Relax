"""Right Extended-Fingers Bicep Stretch — mirror of the left version.

See left_extended_fingers_bicep_stretch.py's docstring.
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
EXERCISE = "right_extended_fingers_bicep_stretch"
VIDEO_NAME = "right_extended_fingers_bicep_stretch.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right bicep", "right forearm")

POSES = {
    0:   {},
    30:  {"upperarm.R": (0, 0, r(30)), "forearm.R": (0, r(-45), 0)},
    60:  {"upperarm.R": (0, 0, r(55)), "forearm.R": (0, r(-90), 0)},
    90:  {"upperarm.R": (0, 0, r(55)), "forearm.R": (0, r(-90), 0)},
    120: {},
}

L.run(globals())
