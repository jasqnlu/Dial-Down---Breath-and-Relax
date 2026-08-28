"""Right Doorway Bicep Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #8. Mirror of
left_doorway_bicep_stretch.py — see that script's docstring for the axis
derivation.

Note which axes mirror and which don't: the torso twist (local-Y) flips sign,
but the shoulder extension (local-X) does NOT — swinging an arm backward is
the same sign for both arms, since it's a sagittal motion with no side.
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
EXERCISE = "right_doorway_bicep_stretch"
VIDEO_NAME = "right_doorway_bicep_stretch.mp4"

CAMERA_AZIMUTH = 270

WORKED_KEYWORDS = ("right bicep", "right chest")

POSES = {
    0: {},
    30: {
        "upperarm.R": (r(22), 0, 0),
        "chest": (0, r(8), 0),
    },
    60: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(16), 0),
        "spine": (0, r(9), 0),
    },
    90: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(16), 0),
        "spine": (0, r(9), 0),
    },
    120: {},
}

L.run(globals())
