"""Standing Doorway Bicep Stretch (Left) — muscle-body + skin-head animation.

Same pose family as left_doorway_bicep_stretch.py — arm pinned straight and
back on a doorframe while the torso rotates away from it. Reuses that
script's exact proven axes (upperarm.L local-X +45 = shoulder extension,
forearm.L local-X -5 = token elbow softening, chest/spine local-Y negative
= rotate the subject's own right, away from the left arm on the frame).

Highlight: Left Biceps.
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
EXERCISE = "standing_doorway_bicep_stretch_left"
VIDEO_NAME = "standing_doorway_bicep_stretch_left.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left bicep",)

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
