"""Assisted Wrist Flexion Stretch (Right) — muscle-body + skin-head animation.

Mirror of assisted_wrist_flexion_stretch_left.py. "Extend your right arm in
front of you, palm down, use your left hand to gently press the back of
your right hand downward." Same rig limitation and approximation
(forward arm extension + forearm local-Y twist). Flagged
`animationIsApproximate`.

Highlight: Right Forearm.
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
EXERCISE = "assisted_wrist_flexion_stretch_right"
VIDEO_NAME = "assisted_wrist_flexion_stretch_right.mp4"

CAMERA_AZIMUTH = -90

WORKED_KEYWORDS = ("right forearm",)

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-45), 0, 0), "forearm.R": (0, r(-45), 0)},
    60:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (0, r(-90), 0)},
    90:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (0, r(-90), 0)},
    120: {},
}

L.run(globals())
