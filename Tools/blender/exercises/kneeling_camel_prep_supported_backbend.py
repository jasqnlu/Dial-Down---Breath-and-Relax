"""Kneeling Camel Prep (Supported Backbend) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same kneeling base + backward-arch axis as seated_thoracic_extension_over_chair_back.py, applied from the upright kneeling silhouette ("kneeling" and "chair-seated" share the same thigh -75 / shin +90 fold on this rig).

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
EXERCISE = "kneeling_camel_prep_supported_backbend"
VIDEO_NAME = "kneeling_camel_prep_supported_backbend.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("abs", "spinal erector")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(-8), 0, 0), "chest": (r(-6), 0, 0)},
    60:  {**_LEGS, "spine": (r(-16), 0, 0), "chest": (r(-12), 0, 0),
          "head": (r(-8), 0, 0)},
    90:  {**_LEGS, "spine": (r(-16), 0, 0), "chest": (r(-12), 0, 0),
          "head": (r(-8), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
