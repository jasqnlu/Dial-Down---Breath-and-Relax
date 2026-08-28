"""Wrist Circles — muscle-body + skin-head animation.

Batch 10. "Extend both arms in front of you, rotate your wrists in large
circles." No wrist joint exists in this rig (rigid hand mitt bound 100% to
the forearm — see rigid_weight() in _lib.py), so an actual circular wrist
path can't be traced. Approximated as: both arms extended forward at chest
height (bilateral version of the wrist-flexor/extensor forward reach), each
forearm's local-Y (twist) and local-Z oscillating out of phase across the
4 keyframes to read as a lazy circular wobble rather than a flat back-and-
forth. Flagged `animationIsApproximate` in SeedData.

Highlight: both Forearms.
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
EXERCISE = "wrist_circles"
VIDEO_NAME = "wrist_circles.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("forearm",)

POSES = {
    0:   {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    30:  {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
          "forearm.L": (0, r(35), 0), "forearm.R": (0, r(-35), 0)},
    60:  {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
          "forearm.L": (r(15), r(-35), 0), "forearm.R": (r(15), r(35), 0)},
    90:  {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
          "forearm.L": (0, r(35), 0), "forearm.R": (0, r(-35), 0)},
    120: {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
}

L.run(globals())
