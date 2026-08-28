"""Supine Pelvic Rock (Gentle Ab Mobilizer) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same subtle spine-only oscillation as pelvic_tilt.py — deliberately not the `hips` bone (would move the whole figure).

Highlight: Abs + Lower Back.
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
EXERCISE = "supine_pelvic_rock_gentle_ab_mobilizer"
VIDEO_NAME = "supine_pelvic_rock_gentle_ab_mobilizer.mp4"

ROLL_DEG = 0
WORKED_KEYWORDS = ("abs", "lower back")
PEAK_FRAME = 30

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
    "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_LEGS},
    30:  {"hips": (r(-90), 0, 0), **_LEGS, "spine": (r(8), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_LEGS},
    90:  {"hips": (r(-90), 0, 0), **_LEGS, "spine": (r(8), 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_LEGS},
}

L.run_supine(globals())
