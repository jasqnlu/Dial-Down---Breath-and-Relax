"""Seated Thoracic Extension Over Chair Back — muscle-body + skin-head animation.

Batch 15 (session push toward 130 exercises). "Sit toward the front edge
of a chair, arch your upper back over the chair back, chest opens, head
tips back." Chair-sitting base (`apply_seated_base`) combined with
standing_back_extension.py's proven backward spine/chest pitch (negative
local-X) and head tip-back — the same axis, just applied from a seated
base instead of standing. Arms behind the head aren't animated (no
hand-target IK).

Highlight: both Chest + Spinal Erectors, matching the exercise's tags.
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
EXERCISE = "seated_thoracic_extension_over_chair_back"
VIDEO_NAME = "seated_thoracic_extension_over_chair_back.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("chest", "spinal erector")

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(-10), 0, 0), "chest": (r(-7), 0, 0)},
    60:  {**_LEGS, "spine": (r(-20), 0, 0), "chest": (r(-15), 0, 0),
          "head": (r(-10), 0, 0)},
    90:  {**_LEGS, "spine": (r(-20), 0, 0), "chest": (r(-15), 0, 0),
          "head": (r(-10), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
