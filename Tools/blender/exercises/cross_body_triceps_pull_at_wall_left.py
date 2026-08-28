"""Cross-Body Triceps Pull at Wall (Left) — muscle-body + skin-head animation.

Same cross-body elbow-adduction-plus-fold shape as the already-shipped
left_cross_body_elbow_pull.py ("bring your arm across your chest, bent at
the elbow") — the wall contact and the assisting hand pressing the elbow
are secondary details this pipeline doesn't animate. Reuses that script's
exact proven axes.

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
EXERCISE = "cross_body_triceps_pull_at_wall_left"
VIDEO_NAME = "cross_body_triceps_pull_at_wall_left.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left tricep",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-10), 0, r(20)), "forearm.L": (r(-40), 0, 0)},
    60:  {"upperarm.L": (r(-15), 0, r(45)), "forearm.L": (r(-90), 0, 0)},
    90:  {"upperarm.L": (r(-15), 0, r(45)), "forearm.L": (r(-90), 0, 0)},
    120: {},
}

L.run(globals())
