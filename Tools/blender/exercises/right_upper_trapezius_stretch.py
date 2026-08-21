"""Right Upper Trapezius Stretch — muscle-body + skin-head animation.

Mirror of left_upper_trapezius_stretch.py. Instructions here: "tilt your
LEFT ear toward your LEFT shoulder" — signs flipped (-Z instead of +Z).

Highlight: Right Trapezius.
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
EXERCISE = "right_upper_trapezius_stretch"
VIDEO_NAME = "right_upper_trapezius_stretch.mp4"

CAMERA_AZIMUTH = 345

WORKED_KEYWORDS = ("right trapezius",)

POSES = {
    0: {},
    30: {"head": (0, 0, r(-18))},
    60: {"head": (0, 0, r(-32))},
    90: {"head": (0, 0, r(-32))},
    120: {},
}

L.run(globals())
