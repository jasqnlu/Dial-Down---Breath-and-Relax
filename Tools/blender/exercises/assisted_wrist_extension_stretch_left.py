"""Assisted Wrist Extension Stretch (Left) — muscle-body + skin-head animation.

Batch 4 hand/wrist follow-up. "Extend your left arm in front of you, palm
up, use your right hand to gently curl your left fingers back toward your
body." Same rig limitation as left_wrist_extensor_stretch.py (no
wrist/finger articulation) — approximated with the same forward arm
extension, forearm twisted the OPPOSITE way (pronated) from the flexion
variant to visually distinguish the two. No hand-target IK for the
assisting hand. Flagged `animationIsApproximate`.

Highlight: Left Forearm.
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
EXERCISE = "assisted_wrist_extension_stretch_left"
VIDEO_NAME = "assisted_wrist_extension_stretch_left.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left forearm",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-45), 0, 0), "forearm.L": (0, r(-25), 0)},
    60:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (r(20), r(-45), 0)},
    90:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (r(20), r(-45), 0)},
    120: {},
}

L.run(globals())
