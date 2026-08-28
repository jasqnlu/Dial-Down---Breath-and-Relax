"""Kneeling Calf Stretch on Cushion (Left) — muscle-body + skin-head animation.

New batch (2026-08-27). "Kneel on a cushion, left foot forward with knee
bent ~90, right knee resting behind; keep the left heel flat, shift
weight forward over the left knee." Reuses the proven half-kneeling
lunge base verbatim (left foot forward = thigh.L=-90/shin.L=90, right
knee down behind), adding the same small forward spine shift used by
the hip-flexor-lunge family for "shift weight forward."

Highlight: Left Calves.
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
EXERCISE = "kneeling_calf_stretch_on_cushion_left"
VIDEO_NAME = "kneeling_calf_stretch_on_cushion_left.mp4"

CAMERA_AZIMUTH = 100
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['left calve'])

POSES = {
    0:   {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
    30:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0), "spine": (r(3), 0, 0)},
    60:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0), "spine": (r(7), 0, 0)},
    90:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0), "spine": (r(7), 0, 0)},
    120: {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
}

L.run_seated(globals())
