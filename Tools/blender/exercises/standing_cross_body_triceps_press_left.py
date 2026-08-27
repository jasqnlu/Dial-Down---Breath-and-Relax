"""Standing Cross-Body Triceps Press (Left) — muscle-body + skin-head animation.

60-exercise batch. Same cross-body elbow-fold shape as cross_body_triceps_pull_at_wall_left.py -- "pull at wall" and "press" are the same underlying motion (reach the straight arm across the chest, use the other forearm to press/pull it in), direct pose reuse.

Highlight: Left Triceps, Left Shoulder.
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
EXERCISE = "standing_cross_body_triceps_press_left"
VIDEO_NAME = "standing_cross_body_triceps_press_left.mp4"

WORKED_KEYWORDS = ("left tricep",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-10), 0, r(20)), "forearm.L": (r(-40), 0, 0)},
    60:  {"upperarm.L": (r(-15), 0, r(45)), "forearm.L": (r(-90), 0, 0)},
    90:  {"upperarm.L": (r(-15), 0, r(45)), "forearm.L": (r(-90), 0, 0)},
    120: {},
}

L.run(globals())
