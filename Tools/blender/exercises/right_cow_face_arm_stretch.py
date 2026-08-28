"""Right Cow-Face Arm Stretch — muscle-body + skin-head animation.

Mirror of left_cow_face_arm_stretch.py — see that script's docstring for
the derivation. RIGHT arm reaches overhead-and-behind (same magnitude as
the left script's working arm), LEFT arm reaches behind the lower back
(same magnitude as the left script's anchoring arm, mirrored sign).

Highlight: Right Triceps + Right Shoulder.
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
EXERCISE = "right_cow_face_arm_stretch"
VIDEO_NAME = "right_cow_face_arm_stretch.mp4"

CAMERA_AZIMUTH = 315

WORKED_KEYWORDS = ("right tricep", "right shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-90), 0, 0),  "forearm.R": (r(-60), 0, 0),
          "upperarm.L": (r(14), 0, r(6)), "forearm.L": (r(-18), 0, r(11))},
    60:  {"upperarm.R": (r(-160), 0, 0), "forearm.R": (r(-150), 0, 0),
          "upperarm.L": (r(28), 0, r(12)), "forearm.L": (r(-34), 0, r(22))},
    90:  {"upperarm.R": (r(-160), 0, 0), "forearm.R": (r(-150), 0, 0),
          "upperarm.L": (r(28), 0, r(12)), "forearm.L": (r(-34), 0, r(22))},
    120: {},
}

L.run(globals())
