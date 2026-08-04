"""Chin Tuck (Forward Head Reset) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #2. A real chin tuck is mostly a horizontal retraction
(double-chin glide), not a full nod — this rig only has a rotation DOF at the
neck, so it's approximated as a SMALL forward pitch (same solved +X-forward
convention as neck_flexion_chin_to_chest.py, ~14 deg vs. that script's 35 deg)
to read as "tuck" rather than the deeper "chin-to-chest" flexion.
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
EXERCISE = "chin_tuck_forward_head_reset"
VIDEO_NAME = "chin_tuck_forward_head_reset.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("back neck",)

POSES = {
    0: {},
    30: {"head": (r(6), 0, 0)},
    60: {"head": (r(14), 0, 0)},
    90: {"head": (r(14), 0, 0)},
    120: {},
}

L.run(globals())
