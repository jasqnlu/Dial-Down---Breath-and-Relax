"""Right Supine Figure-4 Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Mirror of left_supine_figure_4.py — see that script's docstring for the full
derivation (the rigid-mitt-weighting fix that unblocked this exercise, and
the pose-tuning process). Instructions here: "Cross your RIGHT ankle over
your LEFT knee."
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
EXERCISE = "right_supine_figure_4"
VIDEO_NAME = "right_supine_figure_4.mp4"

ROLL_DEG = 0  # flat on the back, no side roll

WORKED_KEYWORDS = ("right glutes",)

_ARMS_REST = {
    "upperarm.L": (r(-30), 0, 0),
    "upperarm.R": (r(-30), 0, 0),
}
_LEFT_LEG = {
    "thigh.L": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
}
_RIGHT_BENT = {
    "thigh.R": (r(-90), 0, 0),
    "shin.R": (r(90), 0, 0),
}
_RIGHT_CROSSED = {
    "thigh.R": (r(-90), 0, r(55)),
    "shin.R": (r(100), 0, r(-10)),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_LEFT_LEG, **_RIGHT_BENT, **_ARMS_REST},
    30:  {"hips": (r(-90), 0, 0), **_LEFT_LEG,
          "thigh.R": (r(-90), 0, r(28)), "shin.R": (r(95), 0, r(-5)), **_ARMS_REST},
    60:  {"hips": (r(-90), 0, 0), **_LEFT_LEG, **_RIGHT_CROSSED, **_ARMS_REST},
    90:  {"hips": (r(-90), 0, 0), **_LEFT_LEG,
          "thigh.R": (r(-90), 0, r(28)), "shin.R": (r(95), 0, r(-5)), **_ARMS_REST},
    120: {"hips": (r(-90), 0, 0), **_LEFT_LEG, **_RIGHT_BENT, **_ARMS_REST},
}

L.run_supine(globals())
