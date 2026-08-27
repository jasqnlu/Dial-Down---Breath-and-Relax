"""Left Standing Figure-4 Stretch — muscle-body + skin-head animation.

New batch (2026-08-27). "Cross your left ankle over your right knee, bend
your standing leg, hinge slightly forward." No independent ankle joint on
this rig, so the ankle-over-knee cross is approximated the same way
right_standing_crossed_leg_fold.py handles an identical shape: the working
thigh externally rotated/abducted (local-Z) to swing it up and across,
combined with a forward torso hinge. Flagged `animationIsApproximate`
(the actual foot-over-knee contact isn't modeled).

Highlight: Left Glutes.
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
EXERCISE = "left_standing_figure_4_stretch"
VIDEO_NAME = "left_standing_figure_4_stretch.mp4"

CAMERA_AZIMUTH = 0
ORTHO_SCALE_MULT = 1.3
WORKED_KEYWORDS = (['left glutes'])

POSES = {
    0:   {"thigh.L": (r(-25), 0, r(-38))},
    30:  {"thigh.L": (r(-25), 0, r(-38)), "spine": (r(15), 0, 0), "chest": (r(10), 0, 0),
          "upperarm.L": (r(-25), 0, 0), "upperarm.R": (r(-25), 0, 0)},
    60:  {"thigh.L": (r(-25), 0, r(-38)), "spine": (r(30), 0, 0), "chest": (r(20), 0, 0), "head": (r(8), 0, 0),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    90:  {"thigh.L": (r(-25), 0, r(-38)), "spine": (r(30), 0, 0), "chest": (r(20), 0, 0), "head": (r(8), 0, 0),
          "upperarm.L": (r(-50), 0, 0), "upperarm.R": (r(-50), 0, 0)},
    120: {"thigh.L": (r(-25), 0, r(-38))},
}

L.run(globals())
