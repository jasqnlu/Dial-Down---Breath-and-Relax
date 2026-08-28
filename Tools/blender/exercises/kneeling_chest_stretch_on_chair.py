"""Kneeling Chest Stretch on Chair — muscle-body + skin-head animation.

Batch 15. "Kneel, rest forearms on a chair seat, let the chest sink
between the arms." Same kneeling seated base as childs_pose.py, but a
shallower forward fold (the chest lowers toward chair-seat height, not all
the way to the floor between the knees) and the arms stay closer to
shoulder height instead of reaching fully overhead, since the forearms
rest on a raised chair seat rather than the floor.

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
EXERCISE = "kneeling_chest_stretch_on_chair"
VIDEO_NAME = "kneeling_chest_stretch_on_chair.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.35

WORKED_KEYWORDS = ("chest", "shoulder")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(20), 0, 0), "chest": (r(15), 0, 0),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    60:  {**_LEGS, "spine": (r(38), 0, 0), "chest": (r(28), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0)},
    90:  {**_LEGS, "spine": (r(38), 0, 0), "chest": (r(28), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
