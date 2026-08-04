"""Cobra Stretch (Prone Press-Up) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #5. The rig has no floor/prone-lying representation, so
this is approximated as a standing-figure backward arch like
standing_back_extension.py, but weighted toward the CHEST (an actual cobra
presses up mostly through the upper back/chest, hips staying low) and with a
more pronounced head tilt (looking up). Same negative-local-X backbend
convention.
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
EXERCISE = "cobra_stretch_prone_press_up"
VIDEO_NAME = "cobra_stretch_prone_press_up.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("abs",)

POSES = {
    0: {},
    30: {"chest": (r(-10), 0, 0)},
    60: {
        "spine": (r(-8), 0, 0),
        "chest": (r(-22), 0, 0),
        "head": (r(-15), 0, 0),
    },
    90: {
        "spine": (r(-8), 0, 0),
        "chest": (r(-22), 0, 0),
        "head": (r(-15), 0, 0),
    },
    120: {},
}

L.run(globals())
