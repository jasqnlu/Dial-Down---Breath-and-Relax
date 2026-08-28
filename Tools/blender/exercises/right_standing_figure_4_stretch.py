"""Right Standing Figure-4 Stretch — mirror of the left version.

See left_standing_figure_4_stretch.py's docstring. Flagged
`animationIsApproximate`.

Highlight: Right Glutes.
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
EXERCISE = "right_standing_figure_4_stretch"
VIDEO_NAME = "right_standing_figure_4_stretch.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = (['right glutes'])

POSES = {
    0:   {"thigh.R": (r(-25), 0, r(38))},
    30:  {"thigh.R": (r(-25), 0, r(38)), "spine": (r(15), 0, 0), "chest": (r(10), 0, 0),
          "upperarm.L": (r(-25), 0, 0), "upperarm.R": (r(-25), 0, 0)},
    60:  {"thigh.R": (r(-25), 0, r(38)), "spine": (r(30), 0, 0), "chest": (r(20), 0, 0), "head": (r(8), 0, 0),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    90:  {"thigh.R": (r(-25), 0, r(38)), "spine": (r(30), 0, 0), "chest": (r(20), 0, 0), "head": (r(8), 0, 0),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    120: {"thigh.R": (r(-25), 0, r(38))},
}

L.run(globals())
