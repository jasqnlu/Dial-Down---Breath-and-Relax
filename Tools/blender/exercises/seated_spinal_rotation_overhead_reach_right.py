"""Seated Spinal Rotation with Overhead Reach (Right) — muscle-body + skin-head.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #12. Mirror of
seated_spinal_rotation_overhead_reach_left.py — see that script's docstring
for the full derivation, including why "(Right)" here names the DIRECTION of
rotation rather than the side being stretched.

Both mirrored axes flip: upperarm local-Z (abduction) and spine/chest local-Y
(twist). The seated leg pose is symmetric and unchanged.
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
EXERCISE = "seated_spinal_rotation_overhead_reach_right"
VIDEO_NAME = "seated_spinal_rotation_overhead_reach_right.mp4"

CAMERA_AZIMUTH = 315
ORTHO_SCALE_MULT = 1.45

WORKED_KEYWORDS = ("right oblique", "right lats", "spinal erector")

# Static seated leg pose, held constant across every keyframe.
_SEATED = {
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
}

POSES = {
    0: dict(_SEATED),
    30: {
        **_SEATED,
        "upperarm.R": (r(-80), 0, 0),
        "spine": (0, r(-10), 0),
    },
    60: {
        **_SEATED,
        "upperarm.R": (r(-150), 0, 0),
        "spine": (0, r(-28), 0),
        "chest": (0, r(-12), 0),
    },
    90: {
        **_SEATED,
        "upperarm.R": (r(-150), 0, 0),
        "spine": (0, r(-28), 0),
        "chest": (0, r(-12), 0),
    },
    120: dict(_SEATED),
}

L.run(globals())
