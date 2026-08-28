"""Seated Butterfly Stretch — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Seated base with BOTH thighs abducted outward (local-Z, the axis proven in left_seated_figure_four_stretch.py) to open the knees like soles pressed together, plus a forward lean.

Highlight: both Adductors.
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
EXERCISE = "seated_butterfly_stretch"
VIDEO_NAME = "seated_butterfly_stretch.mp4"

CAMERA_AZIMUTH = 20
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("left adductor", "right adductor")

_LEGS_REST = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS_REST},
    30:  {**_LEGS_REST, "thigh.L": (r(-75), 0, r(-20)), "thigh.R": (r(-75), 0, r(20))},
    60:  {**_LEGS_REST, "thigh.L": (r(-75), 0, r(-38)), "thigh.R": (r(-75), 0, r(38)),
          "spine": (r(12), 0, 0), "chest": (r(8), 0, 0)},
    90:  {**_LEGS_REST, "thigh.L": (r(-75), 0, r(-38)), "thigh.R": (r(-75), 0, r(38)),
          "spine": (r(12), 0, 0), "chest": (r(8), 0, 0)},
    120: {**_LEGS_REST},
}

L.run_seated(globals())
