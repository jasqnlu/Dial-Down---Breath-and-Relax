"""Left Supine Chest Opener (Open Book) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Mirror of right_supine_chest_opener.py — see that script's docstring for the
supine base pose derivation. Instructions here: "Lie on your RIGHT side...
open your LEFT arm." ROLL_DEG = -90 puts the LEFT side up (verified by
bone-tail Z comparison, mirror of the +90 case).
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
EXERCISE = "left_supine_chest_opener"
VIDEO_NAME = "left_supine_chest_opener.mp4"

ROLL_DEG = -90  # left side up — mirror of right_supine_chest_opener

WORKED_KEYWORDS = ("left chest", "spinal erector")

_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
    "upperarm.R": (r(-90), 0, 0),  # bottom arm stays forward, out of the way
}

POSES = {
    0:   {**_BASE, "upperarm.L": (r(-90), 0, 0), "chest": (0, 0, 0)},
    30:  {**_BASE, "upperarm.L": (r(-150), 0, 0), "chest": (0, r(-10), 0)},
    60:  {**_BASE, "upperarm.L": (r(-215), 0, 0), "chest": (0, r(-20), 0)},
    90:  {**_BASE, "upperarm.L": (r(-150), 0, 0), "chest": (0, r(-10), 0)},
    120: {**_BASE, "upperarm.L": (r(-90), 0, 0), "chest": (0, 0, 0)},
}

L.run_supine(globals())
