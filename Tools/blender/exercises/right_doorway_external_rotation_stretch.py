"""Right Doorway External Rotation Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Mirror of left_doorway_external_rotation_stretch.py — same reasoning (see
that script's docstring): the arm stays pinned (elbow at the side, forearm
bent 90 forward against the doorframe), and it's the torso that twists away.

Sign: doorframe in front of the RIGHT arm; "rotate away" for a right-pinned
arm means twisting to the subject's own left, which is POSITIVE local-Y —
mirrors right_wall_bicep_stretch.py's sign for the same "rotate away from a
wall/frame behind this arm" instruction.
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
EXERCISE = "right_doorway_external_rotation_stretch"
VIDEO_NAME = "right_doorway_external_rotation_stretch.mp4"

CAMERA_AZIMUTH = 320

WORKED_KEYWORDS = ("right shoulder",)

_ARM = {
    "upperarm.R": (0, 0, 0),
    "forearm.R": (r(-90), 0, 0),
}

POSES = {
    0: dict(_ARM),
    30: {**_ARM, "chest": (0, r(6), 0)},
    60: {**_ARM, "chest": (0, r(16), 0), "spine": (0, r(9), 0)},
    90: {**_ARM, "chest": (0, r(16), 0), "spine": (0, r(9), 0)},
    120: dict(_ARM),
}

L.run(globals())
