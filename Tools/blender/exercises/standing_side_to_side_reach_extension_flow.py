"""Standing Side-to-Side Reach Extension Flow — muscle-body + skin-head animation.

60-exercise batch. Standing arms-overhead reach (`upperarm` -140) plus a gentle backward arch reusing standing_back_extension.py's `spine`/`chest` convention, for "interlace fingers overhead, arch back slightly while reaching upward."

Highlight: Left Abs, Right Abs.
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
EXERCISE = "standing_side_to_side_reach_extension_flow"
VIDEO_NAME = "standing_side_to_side_reach_extension_flow.mp4"

WORKED_KEYWORDS = ("abs",)

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0), "upperarm.R": (r(-90), 0, 0)},
    60:  {"upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0),
          "spine": (r(-10), 0, 0), "chest": (r(-8), 0, 0)},
    90:  {"upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0),
          "spine": (r(-10), 0, 0), "chest": (r(-8), 0, 0)},
    120: {},
}

L.run(globals())
