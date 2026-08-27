"""Kneeling Calf Stretch on Cushion (Right) — mirror of the left version.

See kneeling_calf_stretch_on_cushion_left.py's docstring.

Highlight: Right Calves.
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
EXERCISE = "kneeling_calf_stretch_on_cushion_right"
VIDEO_NAME = "kneeling_calf_stretch_on_cushion_right.mp4"

CAMERA_AZIMUTH = -100
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['right calve'])

POSES = {
    0:   {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
    30:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0), "spine": (r(3), 0, 0)},
    60:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0), "spine": (r(7), 0, 0)},
    90:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0), "spine": (r(7), 0, 0)},
    120: {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
}

L.run_seated(globals())
