"""Right Seated Behind-Hip Bicep Stretch — mirror of the left version.

See left_seated_behind_hip_bicep_stretch.py's docstring.
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
EXERCISE = "right_seated_behind_hip_bicep_stretch"
VIDEO_NAME = "right_seated_behind_hip_bicep_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

WORKED_KEYWORDS = ("right bicep",)

_LEGS = {"thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0),
         "thigh.R": (r(-90), 0, 0), "shin.R": (0, 0, 0)}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "upperarm.R": (r(20), 0, 0)},
    60:  {**_LEGS, "upperarm.R": (r(38), 0, 0), "spine": (r(6), 0, 0)},
    90:  {**_LEGS, "upperarm.R": (r(38), 0, 0), "spine": (r(6), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
