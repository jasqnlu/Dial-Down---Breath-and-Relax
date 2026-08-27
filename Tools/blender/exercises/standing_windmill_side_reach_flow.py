"""Standing Windmill Side Reach Flow — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Dynamic flow variant of the standing side-bend family: bends the subject's own right then own left across the loop, same spine/chest local-Z axis, alternating sign.

Highlight: both Obliques.
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
EXERCISE = "standing_windmill_side_reach_flow"
VIDEO_NAME = "standing_windmill_side_reach_flow.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = ("left oblique", "right oblique")

POSES = {
    0:   {},
    30:  {"spine": (0, 0, r(26)), "chest": (0, 0, r(20)), "head": (0, 0, r(6)),
          "upperarm.L": (r(-120), 0, 0)},
    60:  {},
    90:  {"spine": (0, 0, r(-26)), "chest": (0, 0, r(-20)), "head": (0, 0, r(-6)),
          "upperarm.R": (r(-120), 0, 0)},
    120: {},
}

L.run(globals())
