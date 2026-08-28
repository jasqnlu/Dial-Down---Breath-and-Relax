"""Right Half-Kneeling Rear-Foot Instep Stretch — mirror of the left version.

See left_half_kneeling_rear_foot_instep_stretch.py's docstring. Flagged
`animationIsApproximate`.

Highlight: Right Tibialis.
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
EXERCISE = "right_half_kneeling_rear_foot_instep_stretch"
VIDEO_NAME = "right_half_kneeling_rear_foot_instep_stretch.mp4"

CAMERA_AZIMUTH = -100
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['right tibialis'])

POSES = {
    0:   {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
    30:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0), "spine": (r(3), 0, 0)},
    60:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(20), 0, 0), "shin.R": (r(100), 0, 0), "spine": (r(6), 0, 0)},
    90:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(20), 0, 0), "shin.R": (r(100), 0, 0), "spine": (r(6), 0, 0)},
    120: {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
}

L.run_seated(globals())
