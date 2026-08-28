"""Left Wrist Extensor Stretch — muscle-body + skin-head animation.

Batch 10. "Extend your arm in front of you, palm down, press the back of
the hand downward, curling the fingers under." Same rig limitation as
left_wrist_flexor_stretch.py (no wrist/finger articulation) — approximated
with the same forward arm extension, forearm twisted the OPPOSITE way
(pronated, palm-down) to visually distinguish it from the flexor stretch.
Flagged `animationIsApproximate` in SeedData.

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
EXERCISE = "left_wrist_extensor_stretch"
VIDEO_NAME = "left_wrist_extensor_stretch.mp4"

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
