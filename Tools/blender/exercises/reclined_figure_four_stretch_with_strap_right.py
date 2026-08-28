"""Reclined Figure-Four Stretch with Strap (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Mirror of reclined_figure_four_stretch_with_strap_left.py.

Highlight: Right Glutes.
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
EXERCISE = "reclined_figure_four_stretch_with_strap_right"
VIDEO_NAME = "reclined_figure_four_stretch_with_strap_right.mp4"

ROLL_DEG = 0
WORKED_KEYWORDS = ("right glutes",)

_ARMS_REST = {
    "upperarm.L": (r(-30), 0, 0),
    "upperarm.R": (r(-30), 0, 0),
}
_LEFT_LEG = {
    "thigh.L": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
}
_RIGHT_BENT = {
    "thigh.R": (r(-90), 0, 0),
    "shin.R": (r(90), 0, 0),
}
_RIGHT_CROSSED = {
    "thigh.R": (r(-90), 0, r(55)),
    "shin.R": (r(100), 0, r(-10)),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_LEFT_LEG, **_RIGHT_BENT, **_ARMS_REST},
    30:  {"hips": (r(-90), 0, 0), **_LEFT_LEG,
          "thigh.R": (r(-90), 0, r(28)), "shin.R": (r(95), 0, r(-5)), **_ARMS_REST},
    60:  {"hips": (r(-90), 0, 0), **_LEFT_LEG, **_RIGHT_CROSSED, **_ARMS_REST},
    90:  {"hips": (r(-90), 0, 0), **_LEFT_LEG,
          "thigh.R": (r(-90), 0, r(28)), "shin.R": (r(95), 0, r(-5)), **_ARMS_REST},
    120: {"hips": (r(-90), 0, 0), **_LEFT_LEG, **_RIGHT_BENT, **_ARMS_REST},
}

L.run_supine(globals())
