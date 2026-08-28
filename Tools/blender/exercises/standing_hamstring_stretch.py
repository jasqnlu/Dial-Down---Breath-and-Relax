"""Standing Hamstring Stretch — muscle-body + skin-head animation.

Seventh batch, exercise #4. Same shape as standing_forward_fold_ragdoll.py
(hip-hinge forward fold, arms cancelling the parent chest/spine pitch to
hang world-vertical) — see that script's docstring for the axis derivation.
Slightly shallower than the ragdoll version (peak torso pitch 65 deg vs.
75) since this exercise's own instructions caution "keeping your back as
flat as comfortable" and allow bent knees, a gentler stretch than the
ragdoll's "let everything hang heavy" framing.

Highlight: Hamstrings + Lower Back, matching the exercise's target tags.
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
EXERCISE = "standing_hamstring_stretch"
VIDEO_NAME = "standing_hamstring_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.6

WORKED_KEYWORDS = ("hamstring", "lower back")

_SPINE_30, _CHEST_30 = 18, 12
_SPINE_60, _CHEST_60 = 38, 27

POSES = {
    0: {},
    30: {
        "spine": (r(_SPINE_30), 0, 0),
        "chest": (r(_CHEST_30), 0, 0),
        "upperarm.L": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
        "upperarm.R": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
    },
    60: {
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    90: {
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    120: {},
}

L.run(globals())
