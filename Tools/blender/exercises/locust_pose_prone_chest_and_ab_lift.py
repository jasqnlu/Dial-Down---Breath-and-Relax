"""Locust Pose (Prone Chest and Ab Lift) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). The rig has no floor/prone representation (same limitation noted in cobra_stretch_prone_press_up.py), so this is approximated as a standing backward arch weighted toward chest/abs, with the arms trailing back (small upperarm extension) standing in for "arms lift behind you."

Highlight: Abs + Spinal Erectors.
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
EXERCISE = "locust_pose_prone_chest_and_ab_lift"
VIDEO_NAME = "locust_pose_prone_chest_and_ab_lift.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("abs", "spinal erector")

POSES = {
    0: {},
    30: {"chest": (r(-10), 0, 0), "upperarm.L": (r(8), 0, 0), "upperarm.R": (r(8), 0, 0)},
    60: {
        "spine": (r(-8), 0, 0),
        "chest": (r(-22), 0, 0),
        "head": (r(-15), 0, 0),
        "upperarm.L": (r(16), 0, 0), "upperarm.R": (r(16), 0, 0),
    },
    90: {
        "spine": (r(-8), 0, 0),
        "chest": (r(-22), 0, 0),
        "head": (r(-15), 0, 0),
        "upperarm.L": (r(16), 0, 0), "upperarm.R": (r(16), 0, 0),
    },
    120: {},
}

L.run(globals())
