"""Kneeling Side Lunge Adductor Stretch on Cushion (Left) — muscle-body + skin-head animation.

60-exercise batch. Half-kneeling base (rear knee down, same quadruped-rest angle as the hip-flexor-lunge family) with the FRONT leg extended straight out to the side instead of bent forward (`thigh` local-Z abduction on a near-straight leg, reusing frog_stretch_kneeling_groin_stretch.py's proven quadruped-abduction axis) for "left leg extended out to the side, foot flat."

Highlight: Left Adductors.
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
EXERCISE = "kneeling_side_lunge_adductor_stretch_on_cushion_left"
VIDEO_NAME = "kneeling_side_lunge_adductor_stretch_on_cushion_left.mp4"

WORKED_KEYWORDS = ("left adductor",)

_LEGS = {
    "thigh.L": (r(-15), 0, -r(45)), "shin.L": (r(10), 0, 0),
    "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
}

CAMERA_AZIMUTH = 35
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(6), 0, 0)},
    60:  {**_LEGS, "spine": (r(12), 0, 0)},
    90:  {**_LEGS, "spine": (r(12), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
