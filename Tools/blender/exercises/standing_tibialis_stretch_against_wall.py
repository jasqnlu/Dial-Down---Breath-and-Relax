"""Standing Tibialis Stretch Against Wall — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Bilateral version of left/right_standing_tibialis_stretch_toe_point.py — both thighs get the same small (18 deg) hip-extension "foot slides behind" swing at once.

Highlight: both Tibialis.
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
EXERCISE = "standing_tibialis_stretch_against_wall"
VIDEO_NAME = "standing_tibialis_stretch_against_wall.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = ("left tibialis", "right tibialis")

POSES = {
    0:   {},
    30:  {"thigh.L": (r(10), 0, 0), "thigh.R": (r(10), 0, 0)},
    60:  {"thigh.L": (r(18), 0, 0), "thigh.R": (r(18), 0, 0)},
    90:  {"thigh.L": (r(18), 0, 0), "thigh.R": (r(18), 0, 0)},
    120: {},
}

L.run(globals())
