"""Side-Lying Quad Stretch with Strap (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Mirror of side_lying_quad_stretch_with_strap_left.py (ROLL_DEG=+90 puts the RIGHT side up).

Highlight: Right Quadriceps.
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
EXERCISE = "side_lying_quad_stretch_with_strap_right"
VIDEO_NAME = "side_lying_quad_stretch_with_strap_right.mp4"

ROLL_DEG = 90
CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("right quadricep",)

_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
}

POSES = {
    0:   {**_BASE, "shin.R": (r(90), 0, 0)},
    30:  {**_BASE, "shin.R": (r(110), 0, 0)},
    60:  {**_BASE, "shin.R": (r(135), 0, 0)},
    90:  {**_BASE, "shin.R": (r(135), 0, 0)},
    120: {**_BASE, "shin.R": (r(90), 0, 0)},
}

L.run_supine_side(globals())
