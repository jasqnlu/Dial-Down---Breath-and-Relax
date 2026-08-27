"""Kneeling Lat Stretch, Arms Extended — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same bilateral kneeling forward-reach base as kneeling_chest_stretch_on_chair.py (no side bend, symmetric reach), just re-highlighted for lats.

Highlight: both Lats.
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
EXERCISE = "kneeling_lat_stretch_arms_extended"
VIDEO_NAME = "kneeling_lat_stretch_arms_extended.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.35
WORKED_KEYWORDS = ("left lats", "right lats")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(20), 0, 0), "chest": (r(15), 0, 0),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    60:  {**_LEGS, "spine": (r(38), 0, 0), "chest": (r(28), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0)},
    90:  {**_LEGS, "spine": (r(38), 0, 0), "chest": (r(28), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
