"""Right Seated Spinal Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #7. Mirror of left_seated_spinal_twist.py — same twist
magnitudes, opposite local-Y sign, highlighting the right-side muscles instead.
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
EXERCISE = "right_seated_spinal_twist"
VIDEO_NAME = "right_seated_spinal_twist.mp4"

CAMERA_AZIMUTH = 45

WORKED_KEYWORDS = ("right oblique", "spinal erector", "lower back")

POSES = {
    0: {},
    30: {"spine": (0, r(-15), 0)},
    60: {
        "spine": (0, r(-35), 0),
        "chest": (0, r(-10), 0),
    },
    90: {
        "spine": (0, r(-35), 0),
        "chest": (0, r(-10), 0),
    },
    120: {},
}

L.run(globals())
