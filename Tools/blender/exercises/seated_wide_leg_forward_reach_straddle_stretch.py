"""Seated Wide-Leg Forward Reach (Straddle Stretch) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same straight-leg seated base as seated_forward_fold.py (first straight-leg seated pose), with both thighs additionally abducted outward (local-Z) into a straddle before the forward fold.

Highlight: both Adductors + Spinal Erectors.
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
EXERCISE = "seated_wide_leg_forward_reach_straddle_stretch"
VIDEO_NAME = "seated_wide_leg_forward_reach_straddle_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4
WORKED_KEYWORDS = ("left adductor", "right adductor", "spinal erector")

_LEGS = {
    "thigh.L": (r(-90), 0, r(-20)), "thigh.R": (r(-90), 0, r(20)),
    "shin.L": (0, 0, 0), "shin.R": (0, 0, 0),
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
