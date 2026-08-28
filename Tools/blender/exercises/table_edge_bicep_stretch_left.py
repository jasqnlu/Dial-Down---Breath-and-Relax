"""Table-Edge Bicep Stretch (Left) — muscle-body + skin-head animation.

20-exercise thin-coverage batch. "Palm flat on the table edge behind you,
fingers pointing backward, slowly turn your body away from the table."
Direct reuse of left_wall_bicep_stretch.py's shape — same straight-arm
backward reach + shallow torso twist away from the prop, just a different
prop name in the instructions (table edge vs. wall). Sign for "rotate away"
follows the same twist-direction fix documented there (away from a LEFT-side
prop = rotate right = negative local-Y).

Highlight: Left Biceps + Left Forearm, matching the exercise's tags.
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
EXERCISE = "table_edge_bicep_stretch_left"
VIDEO_NAME = "table_edge_bicep_stretch_left.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left bicep", "left forearm")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(20), 0, 0),
        "chest": (0, r(-8), 0),
    },
    60: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(-15), 0),
        "spine": (0, r(-8), 0),
    },
    90: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(-15), 0),
        "spine": (0, r(-8), 0),
    },
    120: {},
}

L.run(globals())
