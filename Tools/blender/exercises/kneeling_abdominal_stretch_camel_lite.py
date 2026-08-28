"""Kneeling Abdominal Stretch (Camel-Lite) — muscle-body + skin-head animation.

60-exercise batch. Kneeling-seated base (apply_seated_base's symmetric thigh -75/shin +90 fold, same as kneeling_tibialis_stretch.py) with a gentle backward arch (`spine`/`chest` negative-X, standing_back_extension.py's proven convention, kept shallow per "arch back only as far as feels easy") instead of that script's upright torso.

Highlight: Left Abs, Right Abs.
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
EXERCISE = "kneeling_abdominal_stretch_camel_lite"
VIDEO_NAME = "kneeling_abdominal_stretch_camel_lite.mp4"

WORKED_KEYWORDS = ("abs",)

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(-8), 0, 0), "chest": (r(-6), 0, 0)},
    60:  {**_LEGS, "spine": (r(-15), 0, 0), "chest": (r(-12), 0, 0)},
    90:  {**_LEGS, "spine": (r(-15), 0, 0), "chest": (r(-12), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
