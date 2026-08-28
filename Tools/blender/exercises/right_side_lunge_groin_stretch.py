"""Right Side Lunge (Groin Stretch) — muscle-body + skin-head animation.

60-exercise batch. Static wide stance (`thigh` local-Z abduction on both legs, reusing standing_adductor_rock_side_to_side.py's proven small-angle convention) with a `spine` lateral lean toward the working (right) side standing in for "shift your weight to the left, bending that knee." Approximated rather than animating an actual single-leg knee bend under bodyweight, which has no proven convention on this rig and risks the same hip-crease tearing documented for large abduction/compound angles elsewhere.

Highlight: Right Adductors.
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
EXERCISE = "right_side_lunge_groin_stretch"
VIDEO_NAME = "right_side_lunge_groin_stretch.mp4"

WORKED_KEYWORDS = ("right adductor",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {"thigh.L": (0, 0, r(18)), "thigh.R": (0, 0, r(18))},
    30:  {"thigh.L": (0, 0, r(18)), "thigh.R": (0, 0, r(18)), "spine": (0, 0, r(10))},
    60:  {"thigh.L": (0, 0, r(18)), "thigh.R": (0, 0, r(18)), "spine": (0, 0, r(16))},
    90:  {"thigh.L": (0, 0, r(18)), "thigh.R": (0, 0, r(18)), "spine": (0, 0, r(16))},
    120: {"thigh.L": (0, 0, r(18)), "thigh.R": (0, 0, r(18))},
}

L.run(globals())
