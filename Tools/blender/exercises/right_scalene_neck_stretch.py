"""Right Scalene Neck Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #6. Mirror of
left_scalene_neck_stretch.py — see that script's docstring for the full
three-axis derivation. Head tilts LEFT (-Z) with the chin rotating slightly
up (-X, unmirrored: pitch is sagittal and has no side) and toward the left
(-Y).

Note the asymmetry in which axes flip: Z and Y are lateral/rotational and
mirror, X is sagittal and does NOT. Getting that wrong would leave the pair
tilting opposite ways but both looking up-and-right.
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

POSES = {
    0: {},
    30: {"head": (r(-4), r(-8), r(-14))},
    60: {"head": (r(-8), r(-15), r(-30))},
    90: {"head": (r(-8), r(-15), r(-30))},
    120: {},
}

L.run(globals())
