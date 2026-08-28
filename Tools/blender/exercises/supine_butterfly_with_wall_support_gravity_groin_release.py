"""Supine Butterfly with Wall Support (Gravity Groin Release) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same supine double-knee-fold + thigh-abduction axes as happy_baby_pose.py, pushed to a deeper soles-together diamond (bigger Z abduction, bigger shin fold).

Highlight: both Adductors.
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
EXERCISE = "supine_butterfly_with_wall_support_gravity_groin_release"
VIDEO_NAME = "supine_butterfly_with_wall_support_gravity_groin_release.mp4"

ROLL_DEG = 0
FORCE_TOPDOWN = True
WORKED_KEYWORDS = ("left adductor", "right adductor")

POSES = {
    0:   {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-78), 0, r(-20)), "thigh.R": (r(-78), 0, r(20)),
          "shin.L": (r(105), 0, 0), "shin.R": (r(105), 0, 0)},
    60:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, r(-40)), "thigh.R": (r(-80), 0, r(40)),
          "shin.L": (r(130), 0, 0), "shin.R": (r(130), 0, 0)},
    90:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, r(-40)), "thigh.R": (r(-80), 0, r(40)),
          "shin.L": (r(130), 0, 0), "shin.R": (r(130), 0, 0)},
    120: {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
