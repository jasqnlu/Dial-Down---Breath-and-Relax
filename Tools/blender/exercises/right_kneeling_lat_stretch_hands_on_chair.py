"""Right Kneeling Lat Stretch, Hands on Chair — muscle-body + skin-head
animation.

Mirror of left_kneeling_lat_stretch_hands_on_chair.py — hands walk left,
right armpit sinks, torso bends toward the subject's own left (negative
local-Z) to stretch the RIGHT lat.

Highlight: Right Lats, matching the exercise's tag.
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
EXERCISE = "right_kneeling_lat_stretch_hands_on_chair"
VIDEO_NAME = "right_kneeling_lat_stretch_hands_on_chair.mp4"

CAMERA_AZIMUTH = -90
ORTHO_SCALE_MULT = 1.35

WORKED_KEYWORDS = ("right lats",)

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(20), 0, r(-6)), "chest": (r(15), 0, r(-10)),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    60:  {**_LEGS, "spine": (r(38), 0, r(-12)), "chest": (r(28), 0, r(-20)),
          "head": (r(10), 0, r(-8)),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0)},
    90:  {**_LEGS, "spine": (r(38), 0, r(-12)), "chest": (r(28), 0, r(-20)),
          "head": (r(10), 0, r(-8)),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "forearm.L": (r(-70), 0, 0), "forearm.R": (r(-70), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
