"""Wrist Flexor Prayer Stretch — muscle-body + skin-head animation.

Ninth batch, exercise #7. Same instructions and pose as
prayer_stretch_palms_together_lower.py ("palms together in front of your
chest, fingers pointing up... lower toward your waist, palms pressed
together") — reuses that script's exact solved pose, including the fix
that scales the forearm Z-angle up as the arm extends so the hands stay
together through the whole lowering motion (see that script's docstring).
Differs only in highlight: this exercise's own target tags include Hand as
well as Forearm.

Highlight: Forearm + Hand (both sides).
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
EXERCISE = "wrist_flexor_prayer_stretch"
VIDEO_NAME = "wrist_flexor_prayer_stretch.mp4"

CAMERA_AZIMUTH = 20

WORKED_KEYWORDS = ("forearm", "hand")

_UPPER = {
    "upperarm.L": (r(14), 0, r(6)),
    "upperarm.R": (r(14), 0, r(-6)),
}

POSES = {
    0:   {**_UPPER, "forearm.L": (r(-95), 0, r(9)),  "forearm.R": (r(-95), 0, r(-9))},
    30:  {**_UPPER, "forearm.L": (r(-75), 0, r(16)), "forearm.R": (r(-75), 0, r(-16))},
    60:  {**_UPPER, "forearm.L": (r(-45), 0, r(28)), "forearm.R": (r(-45), 0, r(-28))},
    90:  {**_UPPER, "forearm.L": (r(-45), 0, r(28)), "forearm.R": (r(-45), 0, r(-28))},
    120: {**_UPPER, "forearm.L": (r(-95), 0, r(9)),  "forearm.R": (r(-95), 0, r(-9))},
}

L.run(globals())
