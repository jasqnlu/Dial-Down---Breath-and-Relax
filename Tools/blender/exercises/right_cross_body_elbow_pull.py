"""Right Cross-Body Elbow Pull — mirror of the left version.

See left_cross_body_elbow_pull.py's docstring.
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
EXERCISE = "right_cross_body_elbow_pull"
VIDEO_NAME = "right_cross_body_elbow_pull.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right tricep", "right shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-10), 0, r(-20)), "forearm.R": (r(-40), 0, 0)},
    60:  {"upperarm.R": (r(-15), 0, r(-45)), "forearm.R": (r(-90), 0, 0)},
    90:  {"upperarm.R": (r(-15), 0, r(-45)), "forearm.R": (r(-90), 0, 0)},
    120: {},
}

L.run(globals())
