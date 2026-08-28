"""World's Greatest Stretch (Right Lead Leg) — mirror of the left version.

See worlds_greatest_stretch_left_lead_leg.py's docstring.

Highlight: Right Hip Flexors + Right Hamstrings + Right Adductors + Spinal Erectors.
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
EXERCISE = "worlds_greatest_stretch_right_lead_leg"
VIDEO_NAME = "worlds_greatest_stretch_right_lead_leg.mp4"

CAMERA_AZIMUTH = -45
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['right hip flexor', 'right adductor', 'spinal erector'])

POSES = {
    0:   {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
    30:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
          "spine": (r(10), r(-10), 0), "upperarm.L": (r(-40), 0, 0)},
    60:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
          "spine": (r(15), r(-32), 0), "chest": (0, r(-14), 0),
          "upperarm.R": (r(-150), 0, r(-15)), "upperarm.L": (r(-60), 0, 0)},
    90:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
          "spine": (r(15), r(-32), 0), "chest": (0, r(-14), 0),
          "upperarm.R": (r(-150), 0, r(-15)), "upperarm.L": (r(-60), 0, 0)},
    120: {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
}

L.run_seated(globals())
