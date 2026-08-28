"""Left Wall-Assisted Overhead Triceps Stretch — muscle-body + skin-head animation.

Batch 16 (session push toward 130 exercises). Geometrically identical to
the already-shipped left_overhead_triceps_stretch.py — "raise the arm
overhead, bend the elbow, drop the hand behind the shoulder blades" — the
wall-assist detail (elbow resting against a wall) isn't animated (no
environment geometry in this pipeline, same simplification as every other
prop-assisted exercise in this family).

Highlight: Left Triceps, the muscle named in the exercise itself.
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
EXERCISE = "left_wall_assisted_overhead_triceps_stretch"
VIDEO_NAME = "left_wall_assisted_overhead_triceps_stretch.mp4"

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
