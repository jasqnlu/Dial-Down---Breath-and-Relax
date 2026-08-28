"""Right Doorframe Hamstring Stretch — muscle-body + skin-head animation.

Mirror of left_doorframe_hamstring_stretch.py — see that script's docstring.
Hip flexion is sagittal and has no side, so `thigh.R` uses the exact same
angles as the left script's `thigh.L`; only which leg stays flat swaps.

Highlight: Right Hamstrings.
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
EXERCISE = "right_doorframe_hamstring_stretch"
VIDEO_NAME = "right_doorframe_hamstring_stretch.mp4"

ROLL_DEG = 0
CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("right hamstring",)

POSES = {
    0:   {"hips": (r(-90), 0, 0), "thigh.L": (0, 0, 0), "shin.L": (0, 0, 0),
          "thigh.R": (r(-30), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), "thigh.L": (0, 0, 0), "shin.L": (0, 0, 0),
          "thigh.R": (r(-65), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), "thigh.L": (0, 0, 0), "shin.L": (0, 0, 0),
          "thigh.R": (r(-90), 0, 0)},
    90:  {"hips": (r(-90), 0, 0), "thigh.L": (0, 0, 0), "shin.L": (0, 0, 0),
          "thigh.R": (r(-90), 0, 0)},
    120: {"hips": (r(-90), 0, 0), "thigh.L": (0, 0, 0), "shin.L": (0, 0, 0),
          "thigh.R": (r(-30), 0, 0)},
}

L.run_supine_side(globals())
