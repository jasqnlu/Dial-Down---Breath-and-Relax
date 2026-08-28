"""Doorway Side Stretch with Overhead Reach (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Mirror of doorway_side_stretch_with_overhead_reach_left.py.

Highlight: Right Obliques + Right Lats.
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
EXERCISE = "doorway_side_stretch_with_overhead_reach_right"
VIDEO_NAME = "doorway_side_stretch_with_overhead_reach_right.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = ("right oblique", "right lats")

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(-12)),
        "chest": (0, 0, r(-10)),
        "upperarm.R": (r(-70), 0, 0),
    },
    60: {
        "spine": (0, 0, r(-26)),
        "chest": (0, 0, r(-20)),
        "head": (0, 0, r(-6)),
        "upperarm.R": (r(-150), 0, 0),
    },
    90: {
        "spine": (0, 0, r(-26)),
        "chest": (0, 0, r(-20)),
        "head": (0, 0, r(-6)),
        "upperarm.R": (r(-150), 0, 0),
    },
    120: {},
}

L.run(globals())
