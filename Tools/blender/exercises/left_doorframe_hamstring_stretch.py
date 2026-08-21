"""Left Doorframe Hamstring Stretch — muscle-body + skin-head animation.

Ninth batch, exercise #1. Single-leg version of legs_up_the_wall.py — one
thigh rotates to fully vertical (-90, "resting the heel on the frame")
while the other leg stays flat and straight ("keep your right leg extended
flat through the doorway": `thigh.R`/`shin.R` held at 0 throughout, the
same "flat along the floor" rest angle legs_up_the_wall's own frame-0 pose
uses). Reuses that script's `CAMERA_AZIMUTH = 90` fix directly (solved for
the same Y-Z swing plane; a single leg swinging into that plane has the
same foreshortening risk from azimuth 0 that the two-leg version had).

Highlight: Left Hamstrings, matching the exercise's target tag.
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
EXERCISE = "left_doorframe_hamstring_stretch"
VIDEO_NAME = "left_doorframe_hamstring_stretch.mp4"

ROLL_DEG = 0
CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left hamstring",)

POSES = {
    0:   {"hips": (r(-90), 0, 0), "thigh.R": (0, 0, 0), "shin.R": (0, 0, 0),
          "thigh.L": (r(-30), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), "thigh.R": (0, 0, 0), "shin.R": (0, 0, 0),
          "thigh.L": (r(-65), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), "thigh.R": (0, 0, 0), "shin.R": (0, 0, 0),
          "thigh.L": (r(-90), 0, 0)},
    90:  {"hips": (r(-90), 0, 0), "thigh.R": (0, 0, 0), "shin.R": (0, 0, 0),
          "thigh.L": (r(-90), 0, 0)},
    120: {"hips": (r(-90), 0, 0), "thigh.R": (0, 0, 0), "shin.R": (0, 0, 0),
          "thigh.L": (r(-30), 0, 0)},
}

L.run_supine_side(globals())
