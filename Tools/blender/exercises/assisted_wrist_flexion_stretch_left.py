"""Assisted Wrist Flexion Stretch (Left) — muscle-body + skin-head animation.

Batch 4 hand/wrist follow-up. "Extend your left arm in front of you, palm
down, use your right hand to gently press the back of your left hand
downward, bending the wrist." Same rig limitation as
left_wrist_flexor_stretch.py (no wrist/finger articulation — the hand is a
rigid convex-hull "mitt" bound 100% to the forearm bone) and the same
approximation: extend the arm forward (upperarm local-X flexion) and twist
the forearm to a supinated (palm-up-ish) orientation via local-Y, the one
degree of freedom this rig has that reads as a wrist-direction change. No
hand-target IK for the pressing hand. Flagged `animationIsApproximate`.

Highlight: Left Forearm, the muscle named in the exercise's own tags.
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
EXERCISE = "assisted_wrist_flexion_stretch_left"
VIDEO_NAME = "assisted_wrist_flexion_stretch_left.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left forearm",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-45), 0, 0), "forearm.L": (0, r(45), 0)},
    60:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (0, r(90), 0)},
    90:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (0, r(90), 0)},
    120: {},
}

L.run(globals())
