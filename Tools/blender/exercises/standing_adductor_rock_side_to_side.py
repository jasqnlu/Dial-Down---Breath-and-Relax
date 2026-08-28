"""Standing Adductor Rock (Side-to-Side) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Standing base with a small alternating thigh local-Z abduction (same axis proven seated/supine, applied standing at a conservative angle) — weight rocks toward the left leg then the right.

Highlight: both Adductors.
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
EXERCISE = "standing_adductor_rock_side_to_side"
VIDEO_NAME = "standing_adductor_rock_side_to_side.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = ("left adductor", "right adductor")

POSES = {
    0:   {},
    30:  {"thigh.L": (0, 0, r(15)), "thigh.R": (0, 0, r(15)), "spine": (0, 0, r(6))},
    60:  {},
    90:  {"thigh.L": (0, 0, r(-15)), "thigh.R": (0, 0, r(-15)), "spine": (0, 0, r(-6))},
    120: {},
}

L.run(globals())
