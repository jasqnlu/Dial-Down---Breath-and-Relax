"""Chair-Assisted Side Bend Stretch (Left) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same torso side-bend as left_standing_side_bend.py — chair is just a hand-rest, not a pose change.

Highlight: Left Obliques.
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
EXERCISE = "chair_assisted_side_bend_stretch_left"
VIDEO_NAME = "chair_assisted_side_bend_stretch_left.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = ("left oblique",)

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(12)),
        "chest": (0, 0, r(10)),
    },
    60: {
        "spine": (0, 0, r(28)),
        "chest": (0, 0, r(22)),
        "head": (0, 0, r(8)),
    },
    90: {
        "spine": (0, 0, r(28)),
        "chest": (0, 0, r(22)),
        "head": (0, 0, r(8)),
    },
    120: {},
}

L.run(globals())
