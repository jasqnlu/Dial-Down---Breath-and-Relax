"""Shoulder Pendulum Swing (Right) — mirror of the left version.

See shoulder_pendulum_swing_left.py's docstring.

No chair/support prop exists on this rig, so the braced hand is approximated as a still forward reach rather than true contact. Flagged `animationIsApproximate`.

Highlight: Right Shoulder + Right Shoulder Joint.
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
EXERCISE = "shoulder_pendulum_swing_right"
VIDEO_NAME = "shoulder_pendulum_swing_right.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.25
WORKED_KEYWORDS = (['right shoulder'])

POSES = {
    0:   {"spine": (r(20), 0, 0), "upperarm.L": (r(-70), 0, 0)},
    30:  {"spine": (r(20), 0, 0), "upperarm.L": (r(-70), 0, 0),
          "upperarm.R": (r(20), 0, r(-10))},
    60:  {"spine": (r(20), 0, 0), "upperarm.L": (r(-70), 0, 0),
          "upperarm.R": (r(35), r(-15), r(10))},
    90:  {"spine": (r(20), 0, 0), "upperarm.L": (r(-70), 0, 0),
          "upperarm.R": (r(20), 0, r(-10))},
    120: {"spine": (r(20), 0, 0), "upperarm.L": (r(-70), 0, 0)},
}

L.run(globals())
