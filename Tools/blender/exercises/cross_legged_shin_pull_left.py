"""Cross-Legged Shin Pull (Left) — muscle-body + skin-head animation.

60-exercise batch. Seated cross-legged (`thigh` local-Z abduction crossing the ankle over the opposite knee, reusing seated_cross_ankle_glute_stretch's proven cross-leg shape) plus a forward hand reach toward the foot. No independent ankle/toe joint exists on this rig (rigid convex-hulled foot 'mitt' 100% weighted to the shin bone -- see the hand/wrist batch's rig-limitation finding, which generalizes identically to feet); the actual toe/ankle motion can't be shown. Flagged animationIsApproximate.

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
EXERCISE = "cross_legged_shin_pull_left"
VIDEO_NAME = "cross_legged_shin_pull_left.mp4"

WORKED_KEYWORDS = ("left tibialis",)

CAMERA_AZIMUTH = 20
ORTHO_SCALE_MULT = 1.3

_LEGS = {
    "thigh.L": (r(-75), 0, -r(30)), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "upperarm.L": (r(-30), 0, 0)},
    60:  {**_LEGS, "upperarm.L": (r(-55), 0, 0), "spine": (r(8), 0, 0)},
    90:  {**_LEGS, "upperarm.L": (r(-55), 0, 0), "spine": (r(8), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
