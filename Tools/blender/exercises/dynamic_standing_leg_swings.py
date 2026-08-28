"""Dynamic Standing Leg Swings — muscle-body + skin-head animation.

New batch (2026-08-27). "Stand on one leg (holding support), swing the
other leg forward and back in a controlled, dynamic motion." A larger-
amplitude version of the thigh local-X flexion/extension axis already
proven at smaller angles across the whole lunge/kick family — no new
axis, just a bigger swing (forward flexion and backward extension on the
same leg, alternating), which is exactly what "dynamic leg swing" is.

Highlight: both Hip Flexors + both Hamstrings.
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
EXERCISE = "dynamic_standing_leg_swings"
VIDEO_NAME = "dynamic_standing_leg_swings.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = (['hip flexor', 'hamstring'])

POSES = {
    0:   {},
    30:  {"thigh.R": (r(-35), 0, 0), "upperarm.L": (r(-20), 0, 0)},
    60:  {"thigh.R": (r(25), 0, 0), "upperarm.R": (r(-15), 0, 0)},
    90:  {"thigh.R": (r(-35), 0, 0), "upperarm.L": (r(-20), 0, 0)},
    120: {},
}

L.run(globals())
