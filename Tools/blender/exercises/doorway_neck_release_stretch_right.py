"""Doorway Neck Release Stretch (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Mirror of doorway_neck_release_stretch_left.py.

Highlight: Right Trapezius + Front Neck.
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
EXERCISE = "doorway_neck_release_stretch_right"
VIDEO_NAME = "doorway_neck_release_stretch_right.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = ("right trapezius", "front neck")

_ARM_UP = {"upperarm.R": (r(-115), 0, r(-10)), "forearm.R": (r(-150), 0, r(30))}
_ARM_MID = {"upperarm.R": (r(-70), 0, r(-6)), "forearm.R": (r(-90), 0, r(18))}

POSES = {
    0:   {},
    30:  {**_ARM_MID, "head": (0, 0, r(4))},
    60:  {**_ARM_UP, "head": (0, 0, r(7))},
    90:  {**_ARM_UP, "head": (0, 0, r(4))},
    120: {},
}

L.run(globals())
