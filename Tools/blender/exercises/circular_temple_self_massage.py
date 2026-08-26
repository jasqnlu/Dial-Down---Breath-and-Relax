"""Circular Temple Self-Massage — muscle-body + skin-head animation.

20-exercise thin-coverage batch. "Place your fingertips lightly on your
temples, make small slow circular motions." Reuses the solved arm-to-head
FK target from left_isometric_neck_side_press.py (own-side hand to own-side
head, above the ear) MIRRORED ONTO BOTH ARMS at once, since this exercise is
bilateral — both hands go to their own temple simultaneously, unlike the
single-arm neck-press family. A small head Z-oscillation stands in for the
"circular motion... reverse direction" cue (the fingertips themselves have
no independent geometry to circle).

Highlight: none — Temple is a face zone with no separate atlas muscle
object (the 41 mappable groups don't include it, same class of limitation
as Jaw/Eye/Forehead), so WORKED_KEYWORDS matches nothing and the clip shows
the arm-to-head reach with no highlighted mesh. Flagged
`animationIsApproximate`.
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
EXERCISE = "circular_temple_self_massage"
VIDEO_NAME = "circular_temple_self_massage.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left temple", "right temple")

# Own-side hand to own-side head, above the ear — mirrored onto both arms.
# See left_isometric_neck_side_press.py's docstring for the numeric fit.
_ARMS_UP = {
    "upperarm.L": (r(-115), 0, r(10)), "forearm.L": (r(-150), 0, r(-30)),
    "upperarm.R": (r(-115), 0, r(-10)), "forearm.R": (r(-150), 0, r(30)),
}

POSES = {
    0:   {},
    30:  {**_ARMS_UP, "head": (0, 0, r(-3))},
    60:  {**_ARMS_UP, "head": (0, 0, r(3))},
    90:  {**_ARMS_UP, "head": (0, 0, r(-3))},
    120: {},
}

L.run(globals())
