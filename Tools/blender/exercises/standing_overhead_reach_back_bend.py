"""Standing Overhead Reach Back Bend — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same backward-arch axis as standing_back_extension.py, with both arms added overhead (upperarm local-X, the proven overhead-flexion axis).

Highlight: Abs + Spinal Erectors.
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
EXERCISE = "standing_overhead_reach_back_bend"
VIDEO_NAME = "standing_overhead_reach_back_bend.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = ("abs", "spinal erector")

POSES = {
    0: {},
    30: {
        "spine": (r(-10), 0, 0),
        "chest": (r(-7), 0, 0),
        "upperarm.L": (r(-60), 0, 0), "upperarm.R": (r(-60), 0, 0),
    },
    60: {
        "spine": (r(-20), 0, 0),
        "chest": (r(-15), 0, 0),
        "head": (r(-10), 0, 0),
        "upperarm.L": (r(-130), 0, 0), "upperarm.R": (r(-130), 0, 0),
    },
    90: {
        "spine": (r(-20), 0, 0),
        "chest": (r(-15), 0, 0),
        "head": (r(-10), 0, 0),
        "upperarm.L": (r(-130), 0, 0), "upperarm.R": (r(-130), 0, 0),
    },
    120: {},
}

L.run(globals())
