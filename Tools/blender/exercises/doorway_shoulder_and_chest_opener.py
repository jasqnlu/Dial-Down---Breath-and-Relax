"""Doorway Shoulder & Chest Opener — muscle-body + skin-head animation.

Batch 11. "Forearms braced on the door frame at shoulder height, elbows
bent 90 degrees, step forward and lean through." Bilateral version of the
already-shipped left_wall_corner_pec_stretch.py shape (moderate upperarm
abduction + forward flexion, forearm folded 90 deg to rest on the frame),
mirrored onto both arms, plus a small forward chest lean standing in for
"step through the doorway" (no leg-stance change modeled — same
simplification as every other standing lean/reach exercise in this
family).

Highlight: both Chest + both Shoulders, matching the exercise's tags.
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
EXERCISE = "doorway_shoulder_and_chest_opener"
VIDEO_NAME = "doorway_shoulder_and_chest_opener.mp4"

CAMERA_AZIMUTH = 0
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
