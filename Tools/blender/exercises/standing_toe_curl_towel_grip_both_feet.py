"""Standing Toe Curl Towel Grip (Both Feet) — muscle-body + skin-head animation.

60-exercise batch. Static standing hold with a small body-weight sway (`spine`, the same device left_step_edge_calf_drop_stretch.py uses to keep an otherwise-static hold from reading as a frozen frame). No independent ankle/toe joint exists on this rig (rigid convex-hulled foot 'mitt' 100% weighted to the shin bone -- see the hand/wrist batch's rig-limitation finding, which generalizes identically to feet); the actual toe/ankle motion can't be shown. Flagged animationIsApproximate.

Highlight: Left Foot, Right Foot.
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
EXERCISE = "standing_toe_curl_towel_grip_both_feet"
VIDEO_NAME = "standing_toe_curl_towel_grip_both_feet.mp4"

WORKED_KEYWORDS = ("foot",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    30:  {"spine": (r(3), 0, 0)},
    60:  {"spine": (r(6), 0, 0)},
    90:  {"spine": (r(3), 0, 0)},
    120: {},
}

L.run(globals())
