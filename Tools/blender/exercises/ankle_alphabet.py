"""Ankle Alphabet — muscle-body + skin-head animation.

60-exercise batch. Same pose/motion as shin_and_ankle_mobiliser.py -- an identically-described exercise under a different name. No independent ankle/toe joint exists on this rig (rigid convex-hulled foot 'mitt' 100% weighted to the shin bone -- see the hand/wrist batch's rig-limitation finding, which generalizes identically to feet); the actual toe/ankle motion can't be shown. Flagged animationIsApproximate.

Highlight: Left Foot, Right Foot.
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
EXERCISE = "ankle_alphabet"
VIDEO_NAME = "ankle_alphabet.mp4"

WORKED_KEYWORDS = ("foot",)

CAMERA_AZIMUTH = 90

POSES = {
    0:   {"thigh.R": (r(-15), 0, 0)},
    30:  {"thigh.R": (r(-15), 0, 0), "shin.R": (r(-10), 0, r(8))},
    60:  {"thigh.R": (r(-15), 0, 0), "shin.R": (r(8), 0, r(-8))},
    90:  {"thigh.R": (r(-15), 0, 0), "shin.R": (r(-6), 0, r(6))},
    120: {"thigh.R": (r(-15), 0, 0)},
}

L.run(globals())
