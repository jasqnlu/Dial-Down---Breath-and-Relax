"""Seated Shin Stretch with Strap (Left) — muscle-body + skin-head animation.

60-exercise batch. Floor-sitting base with the working leg extended straight and the other bent in (asymmetric leg pose, reusing left_seated_hamstring_stretch.py's proven asymmetric convention), both arms reaching forward toward the extended foot. No independent ankle/toe joint exists on this rig (rigid convex-hulled foot 'mitt' 100% weighted to the shin bone -- see the hand/wrist batch's rig-limitation finding, which generalizes identically to feet); the actual toe/ankle motion can't be shown. Flagged animationIsApproximate.

Highlight: Left Tibialis.
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
EXERCISE = "seated_shin_stretch_with_strap_left"
VIDEO_NAME = "seated_shin_stretch_with_strap_left.mp4"

WORKED_KEYWORDS = ("left tibialis",)

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0),
    "thigh.R": (r(-60), 0, r(30)), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(15), 0, 0), "upperarm.L": (r(-25), 0, 0), "upperarm.R": (r(-25), 0, 0)},
    60:  {**_LEGS, "spine": (r(28), 0, 0), "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    90:  {**_LEGS, "spine": (r(28), 0, 0), "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
