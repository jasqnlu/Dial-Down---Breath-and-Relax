"""Table-Supported Wrist Extensor Stretch — muscle-body + skin-head animation.

Batch 4 hand/wrist follow-up. "Kneel or sit in front of a table, place the
backs of both hands flat on the surface, elbows straight, lean your body
weight back." Seated base (`apply_seated_base`, doubling for kneeling —
same convention `seated_thoracic_extension_over_chair_back.py` uses) with
a backward torso lean (negative `spine`, the same axis that script uses for
"arch back over the chair") and both arms extended forward and down toward
table height, forearms pronated (backs of hands down) via local-Y — the
same rotation direction `left_wrist_extensor_stretch.py` uses for a
palm-down orientation, just on both sides and with straighter elbows since
this exercise keeps the arms extended rather than folded.

Highlight: both Forearm (Hand-only target tags can't highlight the mitt
itself — see overhead_finger_interlace_stretch.py's note).
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
EXERCISE = "table_supported_wrist_extensor_stretch"
VIDEO_NAME = "table_supported_wrist_extensor_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left forearm", "right forearm")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(-8), 0, 0),
          "upperarm.L": (r(-30), 0, r(8)), "upperarm.R": (r(-30), 0, r(-8)),
          "forearm.L": (r(10), r(-20), 0), "forearm.R": (r(10), r(20), 0)},
    60:  {**_LEGS, "spine": (r(-15), 0, 0), "chest": (r(-8), 0, 0),
          "upperarm.L": (r(-45), 0, r(10)), "upperarm.R": (r(-45), 0, r(-10)),
          "forearm.L": (r(15), r(-35), 0), "forearm.R": (r(15), r(35), 0)},
    90:  {**_LEGS, "spine": (r(-15), 0, 0), "chest": (r(-8), 0, 0),
          "upperarm.L": (r(-45), 0, r(10)), "upperarm.R": (r(-45), 0, r(-10)),
          "forearm.L": (r(15), r(-35), 0), "forearm.R": (r(15), r(35), 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
