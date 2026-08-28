"""Thumb Extension Stretch (Left) — muscle-body + skin-head animation.

20-exercise thin-coverage batch, hand family. "Hold your left hand up,
use your right hand to gently bend your left thumb back and down." No
finger/thumb articulation on this rig (rigid mitts, no hand-target IK for
a precise thumb grip) — same honest-limit approximation as hook_fist_
tendon_glide.py / assisted_wrist_extension_stretch_left.py: shows the arm
position the exercise sets up (left hand raised in front at face height,
right hand approaching it from the side) with a small oscillating forearm
twist on the working arm so the loop reads as active. The assisting right
hand rises partway toward the left hand but does not attempt precise
finger contact (no thumb geometry to target).

Highlight: Left Forearm (Hand-only target tags can't highlight the mitt
itself — see overhead_finger_interlace_stretch.py's note). Flagged
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
EXERCISE = "thumb_extension_stretch_left"
VIDEO_NAME = "thumb_extension_stretch_left.mp4"

CAMERA_AZIMUTH = 20

WORKED_KEYWORDS = ("left forearm",)

_LEFT_UP = {"upperarm.L": (r(-90), 0, r(10)), "forearm.L": (r(-95), 0, r(8))}
_RIGHT_ASSIST = {"upperarm.R": (r(-70), 0, r(-15)), "forearm.R": (r(-80), 0, r(-10))}

POSES = {
    0:   {},
    30:  {**_LEFT_UP, **_RIGHT_ASSIST, "forearm.L": (r(-95), r(15), r(8))},
    60:  {**_LEFT_UP, **_RIGHT_ASSIST, "forearm.L": (r(-95), r(-15), r(8))},
    90:  {**_LEFT_UP, **_RIGHT_ASSIST, "forearm.L": (r(-95), r(15), r(8))},
    120: {},
}

L.run(globals())
