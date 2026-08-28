"""Standing Quad Stretch with Chair Support (Right) — muscle-body + skin-head animation.

60-exercise batch (session 2026-08-26, cont.). Mirror of standing_quad_stretch_with_chair_support_left.py / right_standing_quad_stretch.py — chair support is only a balance aid, not a pose change.

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
EXERCISE = "standing_quad_stretch_with_chair_support_right"
VIDEO_NAME = "standing_quad_stretch_with_chair_support_right.mp4"

WORKED_KEYWORDS = ("right quadricep",)

CAMERA_AZIMUTH = -90

POSES = {
    0:   {},
    30:  {"shin.R": (r(-60), 0, 0)},
    60:  {"shin.R": (r(-115), 0, 0)},
    90:  {"shin.R": (r(-115), 0, 0)},
    120: {},
}

L.run(globals())
