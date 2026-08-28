"""Doorway Overhead Chest Stretch — muscle-body + skin-head animation.

Batch 15. "Raise both forearms to the top corners of the doorway, elbows
bent near shoulder height, step through and lean forward." Sits between
the two already-shipped doorway heights: reuses
doorway_shoulder_and_chest_opener.py's shoulder-height base shape with a
bit more upperarm lift (short of high_doorway_chest_stretch_upper_chest.py's
above-head reach), matching "top corners... near shoulder height."

Highlight: both Chest, matching the exercise's tags.
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
EXERCISE = "doorway_overhead_chest_stretch"
VIDEO_NAME = "doorway_overhead_chest_stretch.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("chest",)

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(-35), 0, r(-15)), "upperarm.R": (r(-35), 0, r(15)),
        "forearm.L": (r(-30), 0, 0), "forearm.R": (r(-30), 0, 0),
    },
    60: {
        "upperarm.L": (r(-55), 0, r(-26)), "upperarm.R": (r(-55), 0, r(26)),
        "forearm.L": (r(-60), 0, 0), "forearm.R": (r(-60), 0, 0),
        "chest": (r(9), 0, 0),
    },
    90: {
        "upperarm.L": (r(-55), 0, r(-26)), "upperarm.R": (r(-55), 0, r(26)),
        "forearm.L": (r(-60), 0, 0), "forearm.R": (r(-60), 0, 0),
        "chest": (r(9), 0, 0),
    },
    120: {},
}

L.run(globals())
