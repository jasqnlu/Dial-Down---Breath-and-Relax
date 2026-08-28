"""Left Doorway Bicep Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #7. Mechanically the
same shape as left_wall_bicep_stretch.py — arm pinned back and straight while
the torso rotates away from it — differing only in that the hand is on a door
frame at hip height rather than flat on a wall.

Axes (all proven):
  * upperarm.L local-X +45 = shoulder extension, swinging the straight arm
    behind the body ("arm straight and fingers pointing back").
  * forearm.L local-X -5 = a token elbow softening; the instructions call for
    a straight arm, so this stays far shallower than the clasped-hands fold.
  * chest/spine local-Y NEGATIVE = rotate toward the subject's own right.
    "Turn your torso away from your left arm" means turning right, and per
    the corrected convention (ANIMATION_HANDOFF.md "Twist direction") negative
    local-Y is what turns right. Do NOT copy the positive sign from the
    pre-2026-08-08 versions of the seated-twist scripts — it was backwards.
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
EXERCISE = "left_doorway_bicep_stretch"
VIDEO_NAME = "left_doorway_bicep_stretch.mp4"

# Side view with the stretched arm toward camera, matching the wall variant.
CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left bicep", "left chest")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(22), 0, 0),
        "chest": (0, r(-8), 0),
    },
    60: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(-16), 0),
        "spine": (0, r(-9), 0),
    },
    90: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(-16), 0),
        "spine": (0, r(-9), 0),
    },
    120: {},
}

L.run(globals())
