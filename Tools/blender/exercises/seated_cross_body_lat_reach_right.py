"""Seated Cross-Body Lat Reach (Right) — muscle-body + skin-head animation.

60-exercise batch. Seated base, one arm overhead (`upperarm` -150, proven overhead range) plus a `spine`/`chest` side-bend toward the OPPOSITE side (reusing the standing-side-bend Z convention) for "reach across and slightly down toward your opposite knee."

Highlight: Right Lats.
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
EXERCISE = "seated_cross_body_lat_reach_right"
VIDEO_NAME = "seated_cross_body_lat_reach_right.mp4"

WORKED_KEYWORDS = ("right lat",)

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0),
    "thigh.R": (r(-90), 0, 0), "shin.R": (0, 0, 0),
}

CAMERA_AZIMUTH = 15
ORTHO_SCALE_MULT = 1.35

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "upperarm.R": (r(-80), 0, 0), "spine": (0, 0, r(8))},
    60:  {**_LEGS, "upperarm.R": (r(-150), 0, 0), "spine": (0, 0, r(18)), "chest": (0, 0, r(12))},
    90:  {**_LEGS, "upperarm.R": (r(-150), 0, 0), "spine": (0, 0, r(18)), "chest": (0, 0, r(12))},
    120: {**_LEGS},
}

L.run_seated(globals())
