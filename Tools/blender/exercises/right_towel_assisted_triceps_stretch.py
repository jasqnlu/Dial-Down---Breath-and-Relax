"""Right Towel-Assisted Triceps Stretch — mirror of the left version.

See left_towel_assisted_triceps_stretch.py's docstring.
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
EXERCISE = "right_towel_assisted_triceps_stretch"
VIDEO_NAME = "right_towel_assisted_triceps_stretch.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("right tricep", "right shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (r(-60), 0, 0)},
    60:  {"upperarm.R": (r(-160), 0, 0), "forearm.R": (r(-150), 0, 0)},
    90:  {"upperarm.R": (r(-160), 0, 0), "forearm.R": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
