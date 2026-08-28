"""Pigeon Pose (Right Leg Forward) — muscle-body + skin-head animation.

60-exercise batch. Half-kneeling lunge base + front thigh abducted outward (-Z, reusing left_seated_figure_four_stretch.py's proven "opens the bent knee out to the side" axis) for "shin angled toward the left", plus a forward torso fold reusing the seated-forward-fold pitch for "walk your hands forward, lower your torso." Right knee forward (front), left leg extended back (rear).

Highlight: Right Glutes, Left Hip Flexors.
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
EXERCISE = "pigeon_pose_right_leg_forward"
VIDEO_NAME = "pigeon_pose_right_leg_forward.mp4"

WORKED_KEYWORDS = ("right glutes", "left hip")

_LEGS = {
    "thigh.R": (r(-90), 0, r(30)), "shin.R": (r(90), 0, 0),
    "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
}

CAMERA_AZIMUTH = -100
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
