"""Right Finger Extension Stretch — mirror of the left version.

See left_finger_extension_stretch.py's docstring. Flagged
`animationIsApproximate`.

Highlight: Right Forearm.
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
EXERCISE = "right_finger_extension_stretch"
VIDEO_NAME = "right_finger_extension_stretch.mp4"

CAMERA_AZIMUTH = 20
WORKED_KEYWORDS = (['right forearm'])

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-60), 0, r(-10)), "forearm.R": (0, 0, r(-5)),
          "upperarm.L": (r(-55), 0, r(15)), "forearm.L": (r(15), 0, 0)},
    60:  {"upperarm.R": (r(-60), 0, r(-10)), "forearm.R": (r(-15), 0, r(-5)),
          "upperarm.L": (r(-55), 0, r(15)), "forearm.L": (r(15), 0, 0)},
    90:  {"upperarm.R": (r(-60), 0, r(-10)), "forearm.R": (r(-15), 0, r(-5)),
          "upperarm.L": (r(-55), 0, r(15)), "forearm.L": (r(15), 0, 0)},
    120: {},
}

L.run(globals())
