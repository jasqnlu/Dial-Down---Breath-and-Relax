"""Wall Slide (Shoulder Blade Mobility) — muscle-body + skin-head animation.

60-exercise batch. Same bilateral overhead-arm-slide motion as the already-shipped standing_wall_angels_trapezius_mobility_flow.py (W-to-Y-shape arm slide against a wall) -- this is the same exercise concept under a different name, direct pose reuse.

Highlight: Left Shoulder Joint, Right Shoulder Joint, Left Trapezius, Right Trapezius.
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
EXERCISE = "wall_slide_shoulder_blade_mobility"
VIDEO_NAME = "wall_slide_shoulder_blade_mobility.mp4"

WORKED_KEYWORDS = ("trapezius",)

CAMERA_AZIMUTH = 0

POSES = {
    0: {},
    30: {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
         "forearm.L": (r(-20), 0, 0), "forearm.R": (r(-20), 0, 0)},
    60: {"upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0),
         "forearm.L": (r(-10), 0, 0), "forearm.R": (r(-10), 0, 0)},
    90: {"upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0),
         "forearm.L": (r(-10), 0, 0), "forearm.R": (r(-10), 0, 0)},
    120: {},
}

L.run(globals())
