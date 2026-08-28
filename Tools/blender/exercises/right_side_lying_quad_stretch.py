"""Right Side-Lying Quad Stretch — muscle-body + skin-head animation.

60-exercise batch. Same side-lying pose as side_lying_quad_stretch_with_strap_right.py (ROLL_DEG=90 puts the working side up); the strap in that exercise's name is a prop detail only, not a pose difference -- this one just grasps the ankle directly per its own instructions.

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
EXERCISE = "right_side_lying_quad_stretch"
VIDEO_NAME = "right_side_lying_quad_stretch.mp4"

WORKED_KEYWORDS = ("right quadricep",)

ROLL_DEG = 90
CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

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
