"""Thumb Extension Stretch (Right) — muscle-body + skin-head animation.

Mirror of thumb_extension_stretch_left.py — right hand raised, left hand
assists.

Highlight: Right Forearm. Flagged `animationIsApproximate`.
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
EXERCISE = "thumb_extension_stretch_right"
VIDEO_NAME = "thumb_extension_stretch_right.mp4"

CAMERA_AZIMUTH = -20

WORKED_KEYWORDS = ("right forearm",)

_RIGHT_UP = {"upperarm.R": (r(-90), 0, r(-10)), "forearm.R": (r(-95), 0, r(-8))}
_LEFT_ASSIST = {"upperarm.L": (r(-70), 0, r(15)), "forearm.L": (r(-80), 0, r(10))}

POSES = {
    0:   {},
    30:  {**_RIGHT_UP, **_LEFT_ASSIST, "forearm.R": (r(-95), r(-15), r(-8))},
    60:  {**_RIGHT_UP, **_LEFT_ASSIST, "forearm.R": (r(-95), r(15), r(-8))},
    90:  {**_RIGHT_UP, **_LEFT_ASSIST, "forearm.R": (r(-95), r(-15), r(-8))},
    120: {},
}

L.run(globals())
