"""Seated Chair Backbend (Supported Extension) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same seated backward-arch pose as seated_thoracic_extension_over_chair_back.py.

Highlight: Abs + Spinal Erectors.
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
EXERCISE = "seated_chair_backbend_supported_extension"
VIDEO_NAME = "seated_chair_backbend_supported_extension.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("abs", "spinal erector")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(-10), 0, 0), "chest": (r(-7), 0, 0)},
    60:  {**_LEGS, "spine": (r(-20), 0, 0), "chest": (r(-15), 0, 0),
          "head": (r(-10), 0, 0)},
    90:  {**_LEGS, "spine": (r(-20), 0, 0), "chest": (r(-15), 0, 0),
          "head": (r(-10), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
