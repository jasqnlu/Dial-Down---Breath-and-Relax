"""Table-Edge Bicep Stretch (Right) — muscle-body + skin-head animation.

Mirror of table_edge_bicep_stretch_left.py. Rotating away from a RIGHT-side
prop means rotating left, which is POSITIVE local-Y (per the twist-direction
fix: +Y = subject's own left) — the opposite sign from the left variant, same
mirroring rule already applied to left/right_wall_bicep_stretch.

Highlight: Right Biceps + Right Forearm, matching the exercise's tags.
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
EXERCISE = "table_edge_bicep_stretch_right"
VIDEO_NAME = "table_edge_bicep_stretch_right.mp4"

CAMERA_AZIMUTH = -90

WORKED_KEYWORDS = ("right bicep", "right forearm")

POSES = {
    0: {},
    30: {
        "upperarm.R": (r(20), 0, 0),
        "chest": (0, r(8), 0),
    },
    60: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(15), 0),
        "spine": (0, r(8), 0),
    },
    90: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(15), 0),
        "spine": (0, r(8), 0),
    },
    120: {},
}

L.run(globals())
