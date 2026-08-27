"""Runner's Lunge with Rotation (Right) — mirror of the left version.

See runners_lunge_with_rotation_left.py's docstring.

Highlight: Right Hip Flexors + Right Obliques.
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
EXERCISE = "runners_lunge_with_rotation_right"
VIDEO_NAME = "runners_lunge_with_rotation_right.mp4"

CAMERA_AZIMUTH = -45
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['right hip flexor', 'right oblique'])

POSES = {
    0:   {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
    30:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
          "spine": (0, r(-12), 0), "upperarm.R": (r(-60), 0, r(-10))},
    60:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
          "spine": (0, r(-28), 0), "chest": (0, r(-12), 0),
          "upperarm.R": (r(-150), 0, r(-15))},
    90:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
          "spine": (0, r(-28), 0), "chest": (0, r(-12), 0),
          "upperarm.R": (r(-150), 0, r(-15))},
    120: {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
}

L.run_seated(globals())
