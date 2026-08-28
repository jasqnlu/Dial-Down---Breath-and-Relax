"""Wide-Legged Forward Fold — muscle-body + skin-head animation.

Batch 14 (session push toward 130 exercises). Reuses
standing_forward_fold_ragdoll.py's proven forward-hinge shape (spine/chest
pitch + arms canceling the pitch to hang world-vertical) verbatim, adding a
small constant thigh abduction (local-Z) on both legs held through the
whole clip, standing in for "feet wide apart."

Highlight: both Adductors + both Hamstrings, matching the exercise's tags.
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
EXERCISE = "wide_legged_forward_fold"
VIDEO_NAME = "wide_legged_forward_fold.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("adductor", "hamstring")

_SPINE_30, _CHEST_30 = 20, 15
_SPINE_60, _CHEST_60 = 45, 30
_WIDE = {"thigh.L": (0, 0, r(-18)), "thigh.R": (0, 0, r(18))}

POSES = {
    0: {**_WIDE},
    30: {
        **_WIDE,
        "spine": (r(_SPINE_30), 0, 0),
        "chest": (r(_CHEST_30), 0, 0),
        "upperarm.L": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
        "upperarm.R": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
    },
    60: {
        **_WIDE,
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    90: {
        **_WIDE,
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    120: {**_WIDE},
}

L.run(globals())
