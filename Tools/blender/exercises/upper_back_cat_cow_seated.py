"""Upper-Back Cat-Cow (Seated) — muscle-body + skin-head animation.

New batch (2026-08-27). Seated chair-fold base (thigh=-90/shin=+90, the
proven seated convention) with the same spine/chest/head cow<->cat
oscillation already proven standing-free in cat_cow_flow.py's quadruped
version, just on a seated base instead of hands-and-knees.

Highlight: both Trapezius + Spinal Erectors + Front/Back Neck.
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
EXERCISE = "upper_back_cat_cow_seated"
VIDEO_NAME = "upper_back_cat_cow_seated.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
SEATED_DROP = 0.46
WORKED_KEYWORDS = (['trapezius', 'spinal erector'])

POSES = {
    0:   {"thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0), "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
          "spine": (r(-8), 0, 0), "head": (r(-10), 0, 0)},
    30:  {"thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0), "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
          "spine": (r(-4), 0, 0), "head": (r(-5), 0, 0)},
    60:  {"thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0), "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
          "spine": (r(14), 0, 0), "chest": (r(6), 0, 0), "head": (r(14), 0, 0)},
    90:  {"thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0), "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
          "spine": (r(-4), 0, 0), "head": (r(-5), 0, 0)},
    120: {"thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0), "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
          "spine": (r(-8), 0, 0), "head": (r(-10), 0, 0)},
}

L.run_seated(globals())
