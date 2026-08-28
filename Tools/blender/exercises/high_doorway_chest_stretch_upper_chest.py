"""High Doorway Chest Stretch (Upper Chest) — muscle-body + skin-head animation.

Batch 11. Same doorway-lean family as doorway_shoulder_and_chest_opener.py,
but "raise your forearms onto the frame ABOVE HEAD height" — a higher
upperarm flexion (more negative local-X) than the shoulder-height doorway
pair, so the arm silhouette visibly reads as reaching up rather than out to
the sides. Abduction (local-Z) kept smaller than the shoulder-height
version since the arms are more overhead than to the side at this height.

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
EXERCISE = "high_doorway_chest_stretch_upper_chest"
VIDEO_NAME = "high_doorway_chest_stretch_upper_chest.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("chest", "shoulder")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(-60), 0, r(-12)), "upperarm.R": (r(-60), 0, r(12)),
        "forearm.L": (r(-40), 0, 0), "forearm.R": (r(-40), 0, 0),
    },
    60: {
        "upperarm.L": (r(-100), 0, r(-20)), "upperarm.R": (r(-100), 0, r(20)),
        "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0),
        "chest": (r(10), 0, 0),
    },
    90: {
        "upperarm.L": (r(-100), 0, r(-20)), "upperarm.R": (r(-100), 0, r(20)),
        "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0),
        "chest": (r(10), 0, 0),
    },
    120: {},
}

L.run(globals())
