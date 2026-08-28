"""Standing Split Prep Stretch — muscle-body + skin-head animation.

New batch (2026-08-27). Forward-fold torso pitch (same spine/chest
axis and arm-cancellation trick proven in
standing_forward_fold_ragdoll.py) with one leg lifting straight up and
back behind the body (thigh local-X extension on the working leg,
opposite sign from the flexion axis used everywhere else) as the torso
folds — a shallow standing precursor to a full split. Side camera to
show the leg lift silhouette.

Kept to a conservative rear-leg extension for a single-leg standing balance pose; flagged `animationIsApproximate`.

Highlight: both Hamstrings.
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
EXERCISE = "standing_split_prep_stretch"
VIDEO_NAME = "standing_split_prep_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.6
WORKED_KEYWORDS = (['hamstring'])

POSES = {
    0:   {},
    30:  {"spine": (r(20), 0, 0), "chest": (r(15), 0, 0),
          "upperarm.L": (r(-35), 0, 0), "upperarm.R": (r(-35), 0, 0),
          "thigh.R": (r(10), 0, 0)},
    60:  {"spine": (r(45), 0, 0), "chest": (r(30), 0, 0), "head": (r(10), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "thigh.R": (r(30), 0, 0)},
    90:  {"spine": (r(45), 0, 0), "chest": (r(30), 0, 0), "head": (r(10), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0),
          "thigh.R": (r(30), 0, 0)},
    120: {},
}

L.run(globals())
