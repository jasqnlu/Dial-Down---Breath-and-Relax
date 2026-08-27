"""Side-Lying Quad Stretch with Strap (Left) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same side-lying base as left_reclined_quad_stretch_with_strap.py (ROLL_DEG=-90 puts the LEFT side up, lying on the right side) with the left shin folded deep to draw the heel toward the glute.

Highlight: Left Quadriceps.
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
EXERCISE = "side_lying_quad_stretch_with_strap_left"
VIDEO_NAME = "side_lying_quad_stretch_with_strap_left.mp4"

ROLL_DEG = -90
CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("left quadricep",)

_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
    "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_BASE, "shin.L": (r(90), 0, 0)},
    30:  {**_BASE, "shin.L": (r(110), 0, 0)},
    60:  {**_BASE, "shin.L": (r(135), 0, 0)},
    90:  {**_BASE, "shin.L": (r(135), 0, 0)},
    120: {**_BASE, "shin.L": (r(90), 0, 0)},
}

L.run_supine_side(globals())
