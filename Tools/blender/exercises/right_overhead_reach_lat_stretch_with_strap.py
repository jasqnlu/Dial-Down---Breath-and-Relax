"""Right Overhead Reach Lat Stretch with Strap — muscle-body + skin-head
animation.

Mirror of left_overhead_reach_lat_stretch_with_strap.py — see that script's
docstring. Bends the subject's own left (negative local-Z), both arms
overhead.

Highlight: Right Lats + Right Shoulder.
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
EXERCISE = "right_overhead_reach_lat_stretch_with_strap"
VIDEO_NAME = "right_overhead_reach_lat_stretch_with_strap.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right lats", "right shoulder")

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(-12)), "chest": (0, 0, r(-10)),
        "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
    },
    60: {
        "spine": (0, 0, r(-26)), "chest": (0, 0, r(-20)), "head": (0, 0, r(-6)),
        "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0),
    },
    90: {
        "spine": (0, 0, r(-26)), "chest": (0, 0, r(-20)), "head": (0, 0, r(-6)),
        "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0),
    },
    120: {},
}

L.run(globals())
