"""Seated Chair Neck Traction Stretch (Both Sides) — muscle-body + skin-head animation.

60-exercise batch. Chair-sitting base, `head` local-Z alternating both directions in one loop (same axis as left_upper_trapezius_stretch.py, run both ways instead of held to one side, matching "tilt right, then slowly to the left").

Highlight: Left Trapezius, Right Trapezius.
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
EXERCISE = "seated_chair_neck_traction_stretch_both_sides"
VIDEO_NAME = "seated_chair_neck_traction_stretch_both_sides.mp4"

WORKED_KEYWORDS = ("trapezius",)

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

CAMERA_AZIMUTH = 15
ORTHO_SCALE_MULT = 1.3

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "head": (0, 0, r(28))},
    60:  {**_LEGS},
    90:  {**_LEGS, "head": (0, 0, r(-28))},
    120: {**_LEGS},
}

L.run_seated(globals())
