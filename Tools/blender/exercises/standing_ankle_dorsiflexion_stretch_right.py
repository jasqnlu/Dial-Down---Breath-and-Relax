"""Standing Ankle Dorsiflexion Stretch (Right) — mirror of the left version.

See standing_ankle_dorsiflexion_stretch_left.py's docstring. Flagged
`animationIsApproximate`.

Highlight: Right Tibialis + Right Calves.
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
EXERCISE = "standing_ankle_dorsiflexion_stretch_right"
VIDEO_NAME = "standing_ankle_dorsiflexion_stretch_right.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = (['right tibialis', 'right calve'])

POSES = {
    0:   {},
    30:  {"thigh.R": (r(4), 0, 0), "thigh.L": (r(-8), 0, 0), "shin.L": (r(10), 0, 0),
          "upperarm.L": (r(-30), 0, 0), "upperarm.R": (r(-30), 0, 0)},
    60:  {"thigh.R": (r(6), 0, 0), "thigh.L": (r(-14), 0, 0), "shin.L": (r(16), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    90:  {"thigh.R": (r(6), 0, 0), "thigh.L": (r(-14), 0, 0), "shin.L": (r(16), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    120: {},
}

L.run(globals())
