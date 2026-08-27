"""Supine Cross-Body Double Knee Pull (Bilateral Glute Release) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same symmetric double-knee-to-chest fold as double_knee_to_chest_release.py.

Highlight: Lower Back + both Glutes.
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
EXERCISE = "supine_cross_body_double_knee_pull_bilateral_glute_release"
VIDEO_NAME = "supine_cross_body_double_knee_pull_bilateral_glute_release.mp4"

ROLL_DEG = 0
FORCE_TOPDOWN = True
WORKED_KEYWORDS = ("lower back", "left glutes", "right glutes")

POSES = {
    0:   {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, 0), "thigh.R": (r(-80), 0, 0),
          "shin.L": (r(100), 0, 0), "shin.R": (r(100), 0, 0)},
    60:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-85), 0, 0), "thigh.R": (r(-85), 0, 0),
          "shin.L": (r(115), 0, 0), "shin.R": (r(115), 0, 0)},
    90:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, 0), "thigh.R": (r(-80), 0, 0),
          "shin.L": (r(100), 0, 0), "shin.R": (r(100), 0, 0)},
    120: {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
