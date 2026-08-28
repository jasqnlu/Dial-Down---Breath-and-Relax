"""Standing Quad Stretch Against Wall (Left) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same single-leg standing quad fold as left_standing_quad_stretch.py — the wall is just a balance aid, the pose is identical.

Highlight: Left Quadriceps.
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
EXERCISE = "standing_quad_stretch_against_wall_left"
VIDEO_NAME = "standing_quad_stretch_against_wall_left.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = ("left quadricep",)

POSES = {
    0:   {},
    30:  {"shin.L": (r(-60), 0, 0)},
    60:  {"shin.L": (r(-115), 0, 0)},
    90:  {"shin.L": (r(-115), 0, 0)},
    120: {},
}

L.run(globals())
