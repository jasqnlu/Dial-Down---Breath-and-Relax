"""Hook Fist Tendon Glide — muscle-body + skin-head animation.

Batch 4 hand/wrist follow-up. "Hold both hands up in front of you, fingers
straight. Bend only your first and second knuckles to form a hook shape...
repeat the hook-and-straighten motion." No wrist/finger articulation on
this rig (hands are rigid mitts), so the actual finger-hook motion can't be
shown at all — this is the honest limit of the approximation strategy used
throughout this family. What CAN be shown truthfully: the arm position the
exercise sets up ("hands up in front of you", elbows bent, forearms raised
toward chest/face height), with a small back-and-forth forearm twist as the
only available degree of freedom, so the loop reads as active rather than
frozen. `upperarm` stays at a modest forward-and-slightly-out flexion
(elbows in front of the torso, not overhead); `forearm` alternates local-Y
sign each half of the loop.

Highlight: both Forearm (Hand-only target tags can't highlight the mitt
itself — see overhead_finger_interlace_stretch.py's note).
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
EXERCISE = "hook_fist_tendon_glide"
VIDEO_NAME = "hook_fist_tendon_glide.mp4"

CAMERA_AZIMUTH = 20

WORKED_KEYWORDS = ("left forearm", "right forearm")

_UPPER = {"upperarm.L": (r(-65), 0, r(15)), "upperarm.R": (r(-65), 0, r(-15))}

POSES = {
    0:   {},
    30:  {**_UPPER, "forearm.L": (r(-95), 0, r(8)), "forearm.R": (r(-95), 0, r(-8))},
    60:  {**_UPPER, "forearm.L": (r(-95), r(20), r(8)),  "forearm.R": (r(-95), r(-20), r(-8))},
    90:  {**_UPPER, "forearm.L": (r(-95), r(20), r(8)),  "forearm.R": (r(-95), r(-20), r(-8))},
    120: {},
}

L.run(globals())
