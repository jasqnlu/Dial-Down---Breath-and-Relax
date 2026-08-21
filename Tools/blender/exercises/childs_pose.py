"""Child's Pose — muscle-body + skin-head animation.

Batch 13. "Kneel, sit back on your heels, fold your torso forward between
your knees, arms extended overhead on the floor." Kneeling seated base
(`apply_seated_base`, the same `thigh -75 / shin +90` sit-back fold every
other `run_seated` exercise uses for "feet flat"/"sit on the floor")
combined with a much deeper forward spine/chest fold than
seated_forward_fold.py (that script folds over straight legs; here the
torso folds down between already-bent knees, so the total fold reads as
"forehead toward the mat") and arms reaching forward further than that
script's reach-toward-the-feet angle, standing in for "arms extended
overhead on the floor."

Highlight: Spinal Erectors + both Lats, matching the exercise's tags.
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
EXERCISE = "childs_pose"
VIDEO_NAME = "childs_pose.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

WORKED_KEYWORDS = ("spinal erector", "lats")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(35), 0, 0), "chest": (r(25), 0, 0),
          "upperarm.L": (r(-60), 0, 0), "upperarm.R": (r(-60), 0, 0)},
    60:  {**_LEGS, "spine": (r(60), 0, 0), "chest": (r(45), 0, 0),
          "head": (r(15), 0, 0),
          "upperarm.L": (r(-100), 0, 0), "upperarm.R": (r(-100), 0, 0)},
    90:  {**_LEGS, "spine": (r(60), 0, 0), "chest": (r(45), 0, 0),
          "head": (r(15), 0, 0),
          "upperarm.L": (r(-100), 0, 0), "upperarm.R": (r(-100), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
