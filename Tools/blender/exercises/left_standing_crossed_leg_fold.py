"""Left Standing Crossed-Leg Fold — muscle-body + skin-head animation.

Batch 13. "Cross your left leg in front of your right, feet close
together, hinge forward." Reuses standing_forward_fold_ragdoll.py's proven
forward-hinge shape (spine/chest pitch + arms canceling the pitch to hang
world-vertical) verbatim, adding a small constant thigh adduction
(local-Z, the same sign already proven for cross-body/adduction poses) on
the crossing leg held through the whole clip. The actual foot-crossing
contact isn't modeled (legs don't intersect, just angle toward each other)
— a small approximation, flagged `animationIsApproximate`.

Highlight: Left Glutes, matching the exercise's own tag.
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
EXERCISE = "left_standing_crossed_leg_fold"
VIDEO_NAME = "left_standing_crossed_leg_fold.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left glutes",)

_SPINE_30, _CHEST_30 = 20, 15
_SPINE_60, _CHEST_60 = 45, 30
_CROSS = {"thigh.L": (0, 0, r(12))}

POSES = {
    0: {**_CROSS},
    30: {
        **_CROSS,
        "spine": (r(_SPINE_30), 0, 0),
        "chest": (r(_CHEST_30), 0, 0),
        "upperarm.L": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
        "upperarm.R": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
    },
    60: {
        **_CROSS,
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    90: {
        **_CROSS,
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    120: {**_CROSS},
}

L.run(globals())
