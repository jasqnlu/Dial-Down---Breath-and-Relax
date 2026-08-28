"""Left Behind-Head Strap-Assisted Triceps Stretch — muscle-body + skin-head animation.

Batch 16. Same overhead-and-behind triceps shape as the already-shipped
left_overhead_triceps_stretch.py, left_towel_assisted_triceps_stretch.py,
and left_wall_assisted_overhead_triceps_stretch.py — this family's
instructions differ only in the prop used to deepen the stretch (a strap
held overhead vs. a wall vs. nothing), never the pose itself. The
assisting hand/strap isn't animated (no hand-target IK).

Highlight: Left Triceps + Left Shoulder, matching the exercise's tags.
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
EXERCISE = "left_behind_head_strap_assisted_triceps_stretch"
VIDEO_NAME = "left_behind_head_strap_assisted_triceps_stretch.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left tricep", "left shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (r(-60), 0, 0)},
    60:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    90:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
