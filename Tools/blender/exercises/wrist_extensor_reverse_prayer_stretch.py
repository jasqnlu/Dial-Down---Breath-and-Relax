"""Wrist Extensor Reverse-Prayer Stretch — muscle-body + skin-head
animation.

Ninth batch, exercise #8. The reverse of wrist_flexor_prayer_stretch.py's
motion — that exercise starts high (hands at chest) and lowers to the
waist; this one starts low ("backs of hands together in front of your
torso") and RAISES toward the chest. Reuses the exact same pose/angle
values, just with the keyframe order swapped: frame 0 is the flexor
script's peak (hands low, forearms less flexed), the peak here (frame 60)
is the flexor script's frame 0 (hands high, forearms more flexed). Same
scaling-Z-with-reach fix applies for the same reason (a fixed angle
wouldn't keep the hands together across the changing forearm extension).

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
EXERCISE = "wrist_extensor_reverse_prayer_stretch"
VIDEO_NAME = "wrist_extensor_reverse_prayer_stretch.mp4"

CAMERA_AZIMUTH = 20

WORKED_KEYWORDS = ("forearm", "hand")

_UPPER = {
    "upperarm.L": (r(14), 0, r(6)),
    "upperarm.R": (r(14), 0, r(-6)),
}

POSES = {
    0:   {**_UPPER, "forearm.L": (r(-45), 0, r(28)), "forearm.R": (r(-45), 0, r(-28))},
    30:  {**_UPPER, "forearm.L": (r(-75), 0, r(16)), "forearm.R": (r(-75), 0, r(-16))},
    60:  {**_UPPER, "forearm.L": (r(-95), 0, r(9)),  "forearm.R": (r(-95), 0, r(-9))},
    90:  {**_UPPER, "forearm.L": (r(-95), 0, r(9)),  "forearm.R": (r(-95), 0, r(-9))},
    120: {**_UPPER, "forearm.L": (r(-45), 0, r(28)), "forearm.R": (r(-45), 0, r(-28))},
}

L.run(globals())
