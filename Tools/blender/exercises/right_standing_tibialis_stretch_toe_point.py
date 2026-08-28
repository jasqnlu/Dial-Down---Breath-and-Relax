"""Right Standing Tibialis Stretch (Toe Point) — mirror of the left version.

See left_standing_tibialis_stretch_toe_point.py's docstring. Hip extension
is a straight forward/back swing (no lateral component), so it needs no
sign flip between sides — same as the arm-swing angles in
clasped_hands_behind_back.py.
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
EXERCISE = "right_standing_tibialis_stretch_toe_point"
VIDEO_NAME = "right_standing_tibialis_stretch_toe_point.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("right tibialis",)

POSES = {
    0:   {},
    30:  {"thigh.R": (r(10), 0, 0)},
    60:  {"thigh.R": (r(18), 0, 0)},
    90:  {"thigh.R": (r(18), 0, 0)},
    120: {},
}

L.run(globals())
