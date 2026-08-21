"""Left Reclined Quad Stretch with Strap — muscle-body + skin-head animation.

Batch 16 (session push toward 130 exercises). "Lie on your right side,
loop a strap around your left ankle, bend the left knee and draw the heel
toward your glute." Side-lying base (`run_supine_side`, the same
family as left_sleeper_stretch.py / left_supine_chest_opener.py) with
`ROLL_DEG = -90` — per the supine chest-opener docstring, -90 puts the
LEFT side up, i.e. lying on the RIGHT side, matching this exercise's
instructions exactly. Base bent-knee side-lying fold (`thigh -90, shin
+90` both legs, same as left_sleeper_stretch.py) with the LEFT shin folded
further (toward the standing-quad-stretch style deep knee flex) to draw
the heel toward the glute. The strap/hand detail isn't animated (no
hand-target IK).

Highlight: Left Quadriceps, the muscle named in the exercise itself.
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
EXERCISE = "left_reclined_quad_stretch_with_strap"
VIDEO_NAME = "left_reclined_quad_stretch_with_strap.mp4"

ROLL_DEG = -90
CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left quadricep",)

_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
    "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_BASE, "shin.L": (r(90), 0, 0)},
    30:  {**_BASE, "shin.L": (r(110), 0, 0)},
    60:  {**_BASE, "shin.L": (r(135), 0, 0)},
    90:  {**_BASE, "shin.L": (r(135), 0, 0)},
    120: {**_BASE, "shin.L": (r(90), 0, 0)},
}

L.run_supine_side(globals())
