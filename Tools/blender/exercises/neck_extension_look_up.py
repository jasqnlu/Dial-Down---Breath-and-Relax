"""Neck Extension Stretch (Gentle Look-Up) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #1. Mirror image of neck_flexion_chin_to_chest.py's
already-solved axis: positive local-X pitches head forward (-Y world), so
NEGATIVE local-X tilts it back (+Y world) — the "look up" motion. Same side
camera as the flexion script (a front view foreshortens any head pitch).
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
EXERCISE = "neck_extension_look_up"
VIDEO_NAME = "neck_extension_look_up.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("front neck",)

POSES = {
    0: {},
    30: {"head": (r(-10), 0, 0)},
    60: {"head": (r(-25), 0, 0)},
    90: {"head": (r(-25), 0, 0)},
    120: {},
}

L.run(globals())
