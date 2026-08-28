"""Standing Glute Stretch Against Wall (Right) — muscle-body + skin-head animation.

60-exercise batch. Same single-leg standing shin-fold + forward-hip-tuck shape as right_standing_hip_flexor_stretch_foot_elevated.py (foot flat against a wall behind instead of resting on a step is a prop detail, not a pose change) -- retagged for the glute this exercise's own instructions call out.

Highlight: Right Glutes.
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
EXERCISE = "standing_glute_stretch_against_wall_right"
VIDEO_NAME = "standing_glute_stretch_against_wall_right.mp4"

WORKED_KEYWORDS = ("right glutes",)

CAMERA_AZIMUTH = -90

POSES = {
    0:   {},
    30:  {"shin.R": (r(-40), 0, 0), "spine": (r(4), 0, 0)},
    60:  {"shin.R": (r(-90), 0, 0), "spine": (r(8), 0, 0), "chest": (r(5), 0, 0)},
    90:  {"shin.R": (r(-90), 0, 0), "spine": (r(8), 0, 0), "chest": (r(5), 0, 0)},
    120: {},
}

L.run(globals())
