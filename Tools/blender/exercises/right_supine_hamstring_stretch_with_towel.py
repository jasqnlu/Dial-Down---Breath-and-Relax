"""Right Supine Hamstring Stretch with Towel — mirror of the left version.

See left_supine_hamstring_stretch_with_towel.py's docstring.
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
EXERCISE = "right_supine_hamstring_stretch_with_towel"
VIDEO_NAME = "right_supine_hamstring_stretch_with_towel.mp4"

ROLL_DEG = 0

WORKED_KEYWORDS = ("right hamstring",)

_LEFT_REST = {"thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0)}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-82), 0, 0), "shin.R": (r(40), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-90), 0, 0), "shin.R": (0, 0, 0)},
    90:  {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-90), 0, 0), "shin.R": (0, 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_LEFT_REST,
          "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
