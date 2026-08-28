"""Wall-Assisted Toe Extension Stretch (Right) — muscle-body + skin-head animation.

60-exercise batch. Same standing forward-lean shape as standing_hamstring_stretch.py (front leg mostly straight, weight leaning forward), retagged for the front foot pressed against a wall. No independent ankle/toe joint exists on this rig (rigid convex-hulled foot 'mitt' 100% weighted to the shin bone -- see the hand/wrist batch's rig-limitation finding, which generalizes identically to feet); the actual toe/ankle motion can't be shown. Flagged animationIsApproximate.

Highlight: Right Foot.
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
EXERCISE = "wall_assisted_toe_extension_stretch_right"
VIDEO_NAME = "wall_assisted_toe_extension_stretch_right.mp4"

WORKED_KEYWORDS = ("right foot",)

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

POSES = {
    0:   {},
    30:  {"spine": (r(15), 0, 0), "chest": (r(8), 0, 0)},
    60:  {"spine": (r(28), 0, 0), "chest": (r(15), 0, 0)},
    90:  {"spine": (r(28), 0, 0), "chest": (r(15), 0, 0)},
    120: {},
}

L.run(globals())
