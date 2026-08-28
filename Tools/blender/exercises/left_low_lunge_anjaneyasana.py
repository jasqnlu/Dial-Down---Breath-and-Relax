"""Left Low Lunge (Anjaneyasana) — muscle-body + skin-head animation.

60-exercise batch. Half-kneeling lunge base (rear knee untucked/relaxed, matching "lower your knee to the mat ... untuck the toes" rather than the couch-stretch family's deep heel-to-glute fold) plus both arms reaching overhead (`upperarm` -140, the proven overhead range) and a small backward lean (`spine`/`chest` negative-X, reusing standing_back_extension.py's arch) for "raise your arms overhead and lean your hips gently forward" — read here as chest lifting/opening, the visually equivalent motion this rig can show.

Highlight: Left Hip Flexors, Left Abs, Right Abs.
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
EXERCISE = "left_low_lunge_anjaneyasana"
VIDEO_NAME = "left_low_lunge_anjaneyasana.mp4"

WORKED_KEYWORDS = ("left hip", "abs")

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
}

CAMERA_AZIMUTH = 100
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    60:  {**_LEGS, "upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0), "spine": (r(-10), 0, 0), "chest": (r(-8), 0, 0)},
    90:  {**_LEGS, "upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0), "spine": (r(-10), 0, 0), "chest": (r(-8), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
