"""Left Cross-Body Elbow Pull — muscle-body + skin-head animation.

Batch 11. Same shoulder-height adduction shape as
left_cross_body_rear_delt_stretch.py, but the elbow is bent ("bring your
arm across your chest, bent at the elbow, cup the elbow and pull toward
the opposite shoulder") rather than straight. Reuses the same proven
adduction axis/sign at a slightly smaller angle (the bent elbow already
brings the hand closer, so less adduction is needed to read as "across the
chest"), plus a forearm fold. The pulling hand isn't animated (no
hand-target IK).

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
EXERCISE = "left_cross_body_elbow_pull"
VIDEO_NAME = "left_cross_body_elbow_pull.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left tricep", "left shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-10), 0, r(20)), "forearm.L": (r(-40), 0, 0)},
    60:  {"upperarm.L": (r(-15), 0, r(45)), "forearm.L": (r(-90), 0, 0)},
    90:  {"upperarm.L": (r(-15), 0, r(45)), "forearm.L": (r(-90), 0, 0)},
    120: {},
}

L.run(globals())
