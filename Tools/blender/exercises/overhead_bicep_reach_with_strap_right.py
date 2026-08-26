"""Overhead Bicep Reach with Strap (Right) — mirror of the left version.

See overhead_bicep_reach_with_strap_left.py's docstring.
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
EXERCISE = "overhead_bicep_reach_with_strap_right"
VIDEO_NAME = "overhead_bicep_reach_with_strap_right.mp4"

CAMERA_AZIMUTH = 270

WORKED_KEYWORDS = ("right bicep",)

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-70), 0, 0), "forearm.R": (r(-60), 0, 0)},
    60:  {"upperarm.R": (r(-150), 0, 0), "forearm.R": (r(-20), 0, 0)},
    90:  {"upperarm.R": (r(-150), 0, 0), "forearm.R": (r(-20), 0, 0)},
    120: {},
}

L.run(globals())
