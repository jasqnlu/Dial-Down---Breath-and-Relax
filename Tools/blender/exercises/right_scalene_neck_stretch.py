"""Right Scalene Neck Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #6. Mirror of
left_scalene_neck_stretch.py — see that script's docstring for the full
three-axis derivation and its 2026-08-20 sign correction. Head tilts LEFT
(-Z) with the chin rotating slightly up (-X, unmirrored: pitch is sagittal
and has no side) and toward the left (+Y).

Note the asymmetry in which axes flip: Z and Y are lateral/rotational and
mirror, X is sagittal and does NOT. Getting that wrong would leave the pair
tilting opposite ways but both looking up-and-right.

**Arm-to-collarbone fix (2026-08-22, animation-vs-instructions audit):**
mirror of left_scalene_neck_stretch.py's fix — "place your right hand flat
just below your right collarbone" — `upperarm.R=(0,0,10)`,
`forearm.R=(-150,0,30)` (flipped local-Z from the left script's
`upperarm.L`/`forearm.L`).
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
EXERCISE = "right_scalene_neck_stretch"
VIDEO_NAME = "right_scalene_neck_stretch.mp4"

CAMERA_AZIMUTH = 25

WORKED_KEYWORDS = ("front neck", "right trapezius")

_ARM_UP = {"upperarm.R": (0, 0, r(10)), "forearm.R": (r(-150), 0, r(30))}
_ARM_MID = {"upperarm.R": (0, 0, r(6)), "forearm.R": (r(-90), 0, r(18))}

POSES = {
    0: {},
    30: {**_ARM_MID, "head": (r(-4), r(8), r(-14))},
    60: {**_ARM_UP, "head": (r(-8), r(15), r(-30))},
    90: {**_ARM_UP, "head": (r(-8), r(15), r(-30))},
    120: {},
}

L.run(globals())
