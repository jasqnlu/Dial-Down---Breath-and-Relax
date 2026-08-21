"""Right Seated Hamstring Stretch — mirror of the left version.

See left_seated_hamstring_stretch.py's docstring.
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
EXERCISE = "right_seated_hamstring_stretch"
VIDEO_NAME = "right_seated_hamstring_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

WORKED_KEYWORDS = ("right hamstring", "spinal erector")

_LEGS = {
    "thigh.R": (r(-90), 0, 0), "shin.R": (0, 0, 0),
    "thigh.L": (r(-60), 0, r(-30)), "shin.L": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(15), 0, 0), "chest": (r(10), 0, 0),
          "upperarm.L": (r(-20), 0, 0), "upperarm.R": (r(-20), 0, 0)},
    60:  {**_LEGS, "spine": (r(30), 0, 0), "chest": (r(20), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    90:  {**_LEGS, "spine": (r(30), 0, 0), "chest": (r(20), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
