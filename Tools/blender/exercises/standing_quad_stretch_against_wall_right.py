"""Standing Quad Stretch Against Wall (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Mirror of standing_quad_stretch_against_wall_left.py.

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
EXERCISE = "standing_quad_stretch_against_wall_right"
VIDEO_NAME = "standing_quad_stretch_against_wall_right.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = ("right quadricep",)

POSES = {
    0:   {},
    30:  {"shin.R": (r(60), 0, 0)},
    60:  {"shin.R": (r(115), 0, 0)},
    90:  {"shin.R": (r(115), 0, 0)},
    120: {},
}

L.run(globals())
