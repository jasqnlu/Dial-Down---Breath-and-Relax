"""Overhead Bicep Reach with Strap (Left) — muscle-body + skin-head animation.

"Raise arm overhead, bend the elbow with a strap draped down the back, then
straighten the elbow as far as comfortable" — the inverse arc of the
overhead-triceps family (left_overhead_triceps_stretch.py etc.): those hold
the elbow BENT at the peak; this one bends first then straightens toward
the peak to load the biceps instead. Uses the same proven upperarm/forearm
local-X axis (angles ADD into one total rotation about the fixed world
axis, per Gotcha #6) but resolves toward a much straighter total angle at
hold (-150 vs. the triceps family's -310-equivalent).

Highlight: Left Biceps.
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
EXERCISE = "overhead_bicep_reach_with_strap_left"
VIDEO_NAME = "overhead_bicep_reach_with_strap_left.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left bicep",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-70), 0, 0), "forearm.L": (r(-60), 0, 0)},
    60:  {"upperarm.L": (r(-150), 0, 0), "forearm.L": (r(-20), 0, 0)},
    90:  {"upperarm.L": (r(-150), 0, 0), "forearm.L": (r(-20), 0, 0)},
    120: {},
}

L.run(globals())
