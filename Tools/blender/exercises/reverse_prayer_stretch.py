"""Reverse Prayer Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #8. Geometrically close to
clasped_hands_behind_back_muscleonly.py's solved behind-the-back pose — hands
meet behind the back again — so this reuses that script's exact arm-bone axis
signs (upperarm.{L,R} +X/+-Z = shoulder extension + adduction toward midline;
forearm.{L,R} -X = elbow flexion) at ~80% of the shipped clasp magnitude,
since a reverse prayer holds the palms together at the mid-back rather than
gripping the opposite wrist lower down.
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
EXERCISE = "reverse_prayer_stretch"
VIDEO_NAME = "reverse_prayer_stretch.mp4"

CAMERA_AZIMUTH = 38

WORKED_KEYWORDS = ("forearm", "shoulder")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(14), 0, r(6)),
        "upperarm.R": (r(14), 0, r(-6)),
        "forearm.L":  (r(-18), 0, r(11)),
        "forearm.R":  (r(-18), 0, r(-11)),
    },
    60: {
        "upperarm.L": (r(22), 0, r(10)),
        "upperarm.R": (r(22), 0, r(-10)),
        "forearm.L":  (r(-28), 0, r(18)),
        "forearm.R":  (r(-28), 0, r(-18)),
    },
    90: {
        "upperarm.L": (r(22), 0, r(10)),
        "upperarm.R": (r(22), 0, r(-10)),
        "forearm.L":  (r(-28), 0, r(18)),
        "forearm.R":  (r(-28), 0, r(-18)),
    },
    120: {},
}

L.run(globals())
