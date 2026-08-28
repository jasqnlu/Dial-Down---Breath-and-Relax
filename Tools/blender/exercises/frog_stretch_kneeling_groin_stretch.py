"""Frog Stretch (Kneeling Groin Stretch) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Quadruped hands-and-knees base (apply_quadruped_base, same rest angles as cat_cow_flow.py / childs_pose.py) with both thighs abducted outward (local-Z) to widen the knees.

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
EXERCISE = "frog_stretch_kneeling_groin_stretch"
VIDEO_NAME = "frog_stretch_kneeling_groin_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.35
WORKED_KEYWORDS = ("left adductor", "right adductor")

_BASE = {
    "spine": (r(95), 0, 0), "chest": (r(-5), 0, 0),
    "head": (r(-10), 0, 0),
    "upperarm.L": (r(-68), 0, 0), "forearm.L": (r(25), 0, 0),
    "upperarm.R": (r(-68), 0, 0), "forearm.R": (r(25), 0, 0),
}

POSES = {
    0:   {**_BASE, "thigh.L": (r(5), 0, 0), "shin.L": (r(100), 0, 0),
          "thigh.R": (r(5), 0, 0), "shin.R": (r(100), 0, 0)},
    30:  {**_BASE, "thigh.L": (r(5), 0, r(-15)), "shin.L": (r(100), 0, 0),
          "thigh.R": (r(5), 0, r(15)), "shin.R": (r(100), 0, 0)},
    60:  {**_BASE, "thigh.L": (r(5), 0, r(-30)), "shin.L": (r(100), 0, 0),
          "thigh.R": (r(5), 0, r(30)), "shin.R": (r(100), 0, 0)},
    90:  {**_BASE, "thigh.L": (r(5), 0, r(-30)), "shin.L": (r(100), 0, 0),
          "thigh.R": (r(5), 0, r(30)), "shin.R": (r(100), 0, 0)},
    120: {**_BASE, "thigh.L": (r(5), 0, 0), "shin.L": (r(100), 0, 0),
          "thigh.R": (r(5), 0, 0), "shin.R": (r(100), 0, 0)},
}

L.run_quadruped(globals())
