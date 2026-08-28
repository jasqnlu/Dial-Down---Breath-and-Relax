"""Wall-Assisted Ear-to-Shoulder Stretch (Left) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same three-axis head tilt + own-arm-to-collarbone pose as left_scalene_neck_stretch.py.

Highlight: Front Neck + Left Trapezius.
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
EXERCISE = "wall_assisted_ear_to_shoulder_stretch_left"
VIDEO_NAME = "wall_assisted_ear_to_shoulder_stretch_left.mp4"

CAMERA_AZIMUTH = 25
WORKED_KEYWORDS = ("front neck", "left trapezius")

_ARM_UP = {"upperarm.L": (0, 0, r(-10)), "forearm.L": (r(-150), 0, r(-30))}
_ARM_MID = {"upperarm.L": (0, 0, r(-6)), "forearm.L": (r(-90), 0, r(-18))}

POSES = {
    0: {},
    30: {**_ARM_MID, "head": (r(-4), r(-8), r(14))},
    60: {**_ARM_UP, "head": (r(-8), r(-15), r(30))},
    90: {**_ARM_UP, "head": (r(-8), r(-15), r(30))},
    120: {},
}

L.run(globals())
