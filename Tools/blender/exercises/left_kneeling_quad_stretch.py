"""Left Kneeling Quad Stretch — muscle-body + skin-head animation.

60-exercise batch. Half-kneeling lunge base (see generator note) with the REAR (right) shin folded deep (-115, reusing left_standing_quad_stretch.py's proven angle) to bring the heel toward the glute — the actual mechanism named in every variant of this exercise's instructions. Same pose as the couch-stretch variant of this exercise family (no prop, just the reach-back grasp).

Highlight: Left Quadriceps, Left Hip Flexors.
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
EXERCISE = "left_kneeling_quad_stretch"
VIDEO_NAME = "left_kneeling_quad_stretch.mp4"

WORKED_KEYWORDS = ("left quadricep", "left hip")

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(15), 0, 0), "shin.R": (r(115), 0, 0),
}

CAMERA_AZIMUTH = 100
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS},
    60:  {**_LEGS},
    90:  {**_LEGS},
    120: {**_LEGS},
}

L.run_seated(globals())
