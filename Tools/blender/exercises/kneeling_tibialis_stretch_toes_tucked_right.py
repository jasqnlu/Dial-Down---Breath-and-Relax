"""Kneeling Tibialis Stretch, Toes Tucked (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same as kneeling_tibialis_stretch_toes_tucked_left.py, highlight follows the named side.

Highlight: Right Tibialis.
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
EXERCISE = "kneeling_tibialis_stretch_toes_tucked_right"
VIDEO_NAME = "kneeling_tibialis_stretch_toes_tucked_right.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = ("right tibialis",)

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS},
    60:  {**_LEGS},
    90:  {**_LEGS},
    120: {**_LEGS},
}

L.run_seated(globals())
