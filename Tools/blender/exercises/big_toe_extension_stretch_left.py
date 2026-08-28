"""Big Toe Extension Stretch (Left) — muscle-body + skin-head animation.

20-exercise thin-coverage batch, foot family. "Cross your left ankle over
your right knee, pull your left big toe upward and back." Same crossed-ankle
approximation as left_toe_spread_stretch.py / left_plantar_fascia_stretch_
toe_raise.py — no independent toe joint, static held pose.

Highlight: Left Foot. Flagged `animationIsApproximate`.
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
EXERCISE = "big_toe_extension_stretch_left"
VIDEO_NAME = "big_toe_extension_stretch_left.mp4"

CAMERA_AZIMUTH = 20
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left foot",)

_LEGS = {
    "thigh.L": (r(-75), 0, r(-38)), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS},
    60:  {**_LEGS},
    90:  {**_LEGS},
    120: {**_LEGS},
}

L.run_seated(globals())
