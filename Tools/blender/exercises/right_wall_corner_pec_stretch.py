"""Right Wall Corner Pec Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #10. Mirror of
left_wall_corner_pec_stretch.py — see that script's docstring for the axis
derivation and the large-abduction risk note.

Mirrored: upperarm local-Z (abduction) and chest/spine local-Y (twist).
NOT mirrored: forearm local-X (elbow flexion is sagittal, same sign both sides).
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
EXERCISE = "right_wall_corner_pec_stretch"
VIDEO_NAME = "right_wall_corner_pec_stretch.mp4"

CAMERA_AZIMUTH = 330
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("right chest",)

POSES = {
    0: {},
    30: {
        "upperarm.R": (r(-38), 0, r(18)),
        "forearm.R": (r(-30), 0, 0),
    },
    60: {
        "upperarm.R": (r(-62), 0, r(30)),
        "forearm.R": (r(-55), 0, 0),
        "chest": (0, r(18), 0),
        "spine": (0, r(8), 0),
    },
    90: {
        "upperarm.R": (r(-62), 0, r(30)),
        "forearm.R": (r(-55), 0, 0),
        "chest": (0, r(18), 0),
        "spine": (0, r(8), 0),
    },
    120: {},
}

L.run(globals())
