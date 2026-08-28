"""Seated Triceps Stretch with Towel (Left) — muscle-body + skin-head
animation.

Same overhead-and-behind triceps shape as the already-shipped
left_overhead_triceps_stretch.py / left_towel_assisted_triceps_stretch.py —
"sit tall, raise the arm overhead, bend the elbow, walk the other hand up a
towel behind the back." Seated vs. standing makes no visible difference in
this rig (no leg re-pose needed; the arm/torso pose is identical to the
standing version). The assisting hand isn't animated (no hand-target IK).

Highlight: Left Triceps.
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
EXERCISE = "seated_triceps_stretch_with_towel_left"
VIDEO_NAME = "seated_triceps_stretch_with_towel_left.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left tricep",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (r(-60), 0, 0)},
    60:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    90:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
