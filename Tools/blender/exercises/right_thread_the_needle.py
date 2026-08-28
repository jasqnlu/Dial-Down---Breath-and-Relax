"""Right Thread the Needle — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Mirror of left_thread_the_needle.py — see that script's docstring for the
full derivation (the quadruped base pose, and why the reach is an
approximation rather than a literal under-body slide). Instructions here:
"slide your RIGHT arm underneath your body... keep your LEFT hand planted."
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
EXERCISE = "right_thread_the_needle"
VIDEO_NAME = "right_thread_the_needle.mp4"

CAMERA_AZIMUTH = 30  # mirror of the left script's 330 (-30)

WORKED_KEYWORDS = ("right shoulder", "right lats", "spinal erector")

_LEGS = {
    "thigh.L": (r(5), 0, 0),
    "thigh.R": (r(5), 0, 0),
    "shin.L": (r(100), 0, 0),
    "shin.R": (r(100), 0, 0),
}
_HEAD_REST = (r(-10), 0, 0)
_LEFT_ARM_PLANTED = {
    "upperarm.L": (r(-68), 0, 0),
    "forearm.L": (r(25), 0, 0),
}

POSES = {
    0:   {"spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": _HEAD_REST,
          "upperarm.R": (r(-68), 0, 0), "forearm.R": (r(25), 0, 0),
          **_LEGS, **_LEFT_ARM_PLANTED},
    30:  {"spine": (r(95), r(8), 0), "chest": (r(-5), r(16), 0), "head": (r(-10), r(10), 0),
          "upperarm.R": (r(-104), 0, r(18)), "forearm.R": (r(18), 0, 0),
          **_LEGS, **_LEFT_ARM_PLANTED},
    60:  {"spine": (r(95), r(15), 0), "chest": (r(-5), r(30), 0), "head": (r(-10), r(20), 0),
          "upperarm.R": (r(-140), 0, r(35)), "forearm.R": (r(10), 0, 0),
          **_LEGS, **_LEFT_ARM_PLANTED},
    90:  {"spine": (r(95), r(8), 0), "chest": (r(-5), r(16), 0), "head": (r(-10), r(10), 0),
          "upperarm.R": (r(-104), 0, r(18)), "forearm.R": (r(18), 0, 0),
          **_LEGS, **_LEFT_ARM_PLANTED},
    120: {"spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": _HEAD_REST,
          "upperarm.R": (r(-68), 0, 0), "forearm.R": (r(25), 0, 0),
          **_LEGS, **_LEFT_ARM_PLANTED},
}

L.run_quadruped(globals())
