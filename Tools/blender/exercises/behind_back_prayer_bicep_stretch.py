"""Behind-Back Prayer Bicep Stretch — muscle-body + skin-head animation.

Bilateral version of the wall/doorway bicep family's shoulder-extension
shape (upperarm local-X +X = swing back, proven since
clasped_hands_behind_back_muscleonly.py), plus a small adduction (local-Z,
mirrored L/R) so the two straight arms angle toward the midline as if
pressing palms together behind the back, instead of pinning flat on a
single wall. Elbows stay near-straight per "elbows straight" in the
instructions, so no forearm fold beyond a token softening. No torso twist
(the instructions are symmetric, "stand tall").

Highlight: Left Biceps + Right Biceps.
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
EXERCISE = "behind_back_prayer_bicep_stretch"
VIDEO_NAME = "behind_back_prayer_bicep_stretch.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left bicep", "right bicep")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(18), 0, r(6)),
        "upperarm.R": (r(18), 0, r(-6)),
        "forearm.L": (r(-5), 0, 0),
        "forearm.R": (r(-5), 0, 0),
    },
    60: {
        "upperarm.L": (r(36), 0, r(10)),
        "upperarm.R": (r(36), 0, r(-10)),
        "forearm.L": (r(-5), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "spine": (r(-4), 0, 0),
    },
    90: {
        "upperarm.L": (r(36), 0, r(10)),
        "upperarm.R": (r(36), 0, r(-10)),
        "forearm.L": (r(-5), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "spine": (r(-4), 0, 0),
    },
    120: {},
}

L.run(globals())
