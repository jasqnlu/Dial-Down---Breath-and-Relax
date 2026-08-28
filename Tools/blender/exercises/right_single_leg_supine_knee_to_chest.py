"""Right Single-Leg Supine Knee-to-Chest — muscle-body + skin-head
animation.

Mirror of left_single_leg_supine_knee_to_chest.py — see that script's
docstring for the full derivation (deepening the working thigh past the
symmetric -75 ceiling, re-tested and clean for a single-leg fold; the new
FORCE_TOPDOWN override so the hip-flexion motion doesn't foreshorten away
under the family's usual oblique camera). Hip flexion is sagittal and has
no side, so `thigh.R`/`shin.R` use the exact same numbers as the left
script's `thigh.L`/`shin.L` — only which leg is the constant "rest" one and
the highlight side flip.

Highlight: Lower Back + Right Glutes.
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
EXERCISE = "right_single_leg_supine_knee_to_chest"
VIDEO_NAME = "right_single_leg_supine_knee_to_chest.mp4"

ROLL_DEG = 0
FORCE_TOPDOWN = True

WORKED_KEYWORDS = ("lower back", "right glutes")

_LEFT_REST = {"thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0)}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-88), 0, 0), "shin.R": (r(105), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-100), 0, 0), "shin.R": (r(120), 0, 0)},
    90:  {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-88), 0, 0), "shin.R": (r(105), 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
