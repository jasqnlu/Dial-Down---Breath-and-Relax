"""Overhead Finger Interlace Stretch — muscle-body + skin-head animation.

Batch 4 hand/wrist follow-up. "Interlace your fingers, turn palms away,
straighten your arms overhead, press palms upward." No wrist/finger
articulation on this rig (hands are rigid mitts), so the "interlace" itself
can't be shown; approximated with both arms reaching overhead
(`upperarm` local-X toward the proven -150/-160 ceiling, per the
overhead-reach family) and `forearm` local-Z scaling up toward the peak —
the same "close the hand gap as the reach deepens" technique
`prayer_stretch_palms_together_lower.py` uses, applied overhead instead of
low, so the two mitts read as coming together at the top.

Highlight: both Forearm (the nearest highlight-able muscle to the exercise's
Hand-only target tags — hand "mitts" are always neutral-material, see
_lib.py's rigid_weight/hull note, so Hand-only exercises can never
highlight the hand itself).
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
EXERCISE = "overhead_finger_interlace_stretch"
VIDEO_NAME = "overhead_finger_interlace_stretch.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left forearm", "right forearm")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, r(15)),  "upperarm.R": (r(-90), 0, r(-15)),
          "forearm.L": (r(-10), 0, r(25)),  "forearm.R": (r(-10), 0, r(-25))},
    60:  {"upperarm.L": (r(-155), 0, r(22)), "upperarm.R": (r(-155), 0, r(-22)),
          "forearm.L": (r(-15), 0, r(55)),   "forearm.R": (r(-15), 0, r(-55))},
    90:  {"upperarm.L": (r(-155), 0, r(22)), "upperarm.R": (r(-155), 0, r(-22)),
          "forearm.L": (r(-15), 0, r(55)),   "forearm.R": (r(-15), 0, r(-55))},
    120: {},
}

L.run(globals())
