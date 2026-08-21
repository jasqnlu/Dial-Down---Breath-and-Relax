"""Doorway Pec Stretch (Mid Chest) — muscle-body + skin-head animation.

Batch 11. Mechanically the same bilateral braced-forearm doorway lean as
doorway_shoulder_and_chest_opener.py (near-identical instructions: forearms
on the frame at shoulder height, elbows bent 90, step through) — kept the
same pose, viewed from a 3/4 angle for visual variety between the two
near-duplicate doorway exercises.

Highlight: both Chest + both Shoulders.
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
EXERCISE = "doorway_pec_stretch_mid_chest"
VIDEO_NAME = "doorway_pec_stretch_mid_chest.mp4"

CAMERA_AZIMUTH = 30
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("chest", "shoulder")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(-20), 0, r(-18)), "upperarm.R": (r(-20), 0, r(18)),
        "forearm.L": (r(-30), 0, 0), "forearm.R": (r(-30), 0, 0),
    },
    60: {
        "upperarm.L": (r(-32), 0, r(-30)), "upperarm.R": (r(-32), 0, r(30)),
        "forearm.L": (r(-60), 0, 0), "forearm.R": (r(-60), 0, 0),
        "chest": (r(8), 0, 0),
    },
    90: {
        "upperarm.L": (r(-32), 0, r(-30)), "upperarm.R": (r(-32), 0, r(30)),
        "forearm.L": (r(-60), 0, 0), "forearm.R": (r(-60), 0, 0),
        "chest": (r(8), 0, 0),
    },
    120: {},
}

L.run(globals())
