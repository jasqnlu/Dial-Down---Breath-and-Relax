"""Pigeon Pose (Left Leg Forward) — muscle-body + skin-head animation.

60-exercise batch. Mirror of pigeon_pose_right_leg_forward.py. Left knee forward (front), right leg extended back (rear).

Highlight: Left Glutes, Right Hip Flexors.
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
EXERCISE = "pigeon_pose_left_leg_forward"
VIDEO_NAME = "pigeon_pose_left_leg_forward.mp4"

WORKED_KEYWORDS = ("left glutes", "right hip")

_LEGS = {
    "thigh.L": (r(-90), 0, -r(30)), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
}

CAMERA_AZIMUTH = 100
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(10), 0, 0)},
    60:  {**_LEGS, "spine": (r(22), 0, 0), "chest": (r(15), 0, 0)},
    90:  {**_LEGS, "spine": (r(22), 0, 0), "chest": (r(15), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
