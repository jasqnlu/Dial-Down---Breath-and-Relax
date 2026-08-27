"""Supine Side-to-Side Knee Drop (Dynamic Oblique Flow) — muscle-body + skin-head animation.

60-exercise batch. Same windshield-wiper knee-swing mechanism as right_supine_spinal_twist.py (proven safe at peak 10deg/quarter 6deg after the 2026-08-19 swing-amplitude fix), without that script's head turn -- this exercise's own motion is purely the knee drop.

Highlight: Left Obliques, Right Obliques.
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
EXERCISE = "supine_side_to_side_knee_drop_dynamic_oblique_flow"
VIDEO_NAME = "supine_side_to_side_knee_drop_dynamic_oblique_flow.mp4"

WORKED_KEYWORDS = ("oblique",)

ROLL_DEG = 0
CAMERA_AZIMUTH = 0

_BASE = {"hips": (r(-90), 0, 0), "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0)}

POSES = {
    0:   {**_BASE},
    30:  {**_BASE, "thigh.L": (r(-75), 0, r(6)), "thigh.R": (r(-75), 0, r(6))},
    60:  {**_BASE, "thigh.L": (r(-75), 0, r(10)), "thigh.R": (r(-75), 0, r(10))},
    90:  {**_BASE, "thigh.L": (r(-75), 0, r(-10)), "thigh.R": (r(-75), 0, r(-10))},
    120: {**_BASE},
}

L.run_supine(globals())
