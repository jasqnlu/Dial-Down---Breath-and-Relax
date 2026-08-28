"""Prone Y-T-W Raise (Upper Back Activation Flow) — muscle-body + skin-head animation.

60-exercise batch. Prone base (`hips` local-X=+90, the proven face-down half of the supine-probe finding) cycling both arms through three forward-flexion magnitudes to stand in for Y/T/W (a literal T-shape is the documented abduction axis that tears this arms-down mesh, so all three letters are approximated as different degrees of forward reach instead of true abduction). Flagged animationIsApproximate.

Highlight: Left Trapezius, Right Trapezius.
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
EXERCISE = "prone_y_t_w_raise_upper_back_activation_flow"
VIDEO_NAME = "prone_y_t_w_raise_upper_back_activation_flow.mp4"

WORKED_KEYWORDS = ("trapezius",)

ROLL_DEG = 0
FORCE_TOPDOWN = False
CAMERA_AZIMUTH = 0

_BASE = {"hips": (r(90), 0, 0)}

POSES = {
    0:   {**_BASE, "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0)},
    30:  {**_BASE, "upperarm.L": (r(-160), 0, 0), "upperarm.R": (r(-160), 0, 0)},
    60:  {**_BASE, "upperarm.L": (r(-120), 0, 0), "upperarm.R": (r(-120), 0, 0)},
    90:  {**_BASE, "upperarm.L": (r(-90), 0, r(-20)), "upperarm.R": (r(-90), 0, r(20)),
          "forearm.L": (r(-40), 0, 0), "forearm.R": (r(-40), 0, 0)},
    120: {**_BASE, "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0)},
}

L.run_supine(globals())
