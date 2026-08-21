"""Left Towel-Assisted Triceps Stretch — muscle-body + skin-head animation.

Batch 10 (session push toward 130 exercises). Pose is geometrically
identical to the already-shipped `left_overhead_triceps_stretch.py` —
"reach overhead, bend the elbow, drop the hand behind your head" — the
towel prop and the assisting hand (reaching up the back from below) are
both secondary-hand details this pipeline doesn't animate (same
simplification as the rest of the family: no hand-target IK). Highlight
carries over the exact same worked muscles.
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
EXERCISE = "left_towel_assisted_triceps_stretch"
VIDEO_NAME = "left_towel_assisted_triceps_stretch.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left tricep", "left shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (r(-60), 0, 0)},
    60:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    90:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
