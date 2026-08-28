"""Left Seated Hamstring Stretch — muscle-body + skin-head animation.

Batch 12. "Sit on the floor, left leg extended, right foot drawn in toward
the inner thigh, hinge forward over the left leg." Floor-sitting base
(`apply_seated_base`, same as seated_forward_fold.py), with the two legs
posed DIFFERENTLY — the extended leg stays straight (`thigh -90, shin 0`,
seated_forward_fold's straight-leg convention) while the other is bent and
abducted out to the side (`thigh` less flexed + externally rotated via
local-Z, `shin` folded), approximating a foot drawn toward the inner
thigh. Asymmetric left/right leg poses are already proven safe together
(the supine single-leg knee-to-chest pair), just not yet in the seated
family. Forward hinge reuses seated_forward_fold's spine/chest pitch.

Highlight: Left Hamstrings + Spinal Erectors (covers the same region as
the "Lower Back" tag without over-highlighting).
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
EXERCISE = "left_seated_hamstring_stretch"
VIDEO_NAME = "left_seated_hamstring_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

WORKED_KEYWORDS = ("left hamstring", "spinal erector")

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0),
    "thigh.R": (r(-60), 0, r(30)), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(15), 0, 0), "chest": (r(10), 0, 0),
          "upperarm.L": (r(-20), 0, 0), "upperarm.R": (r(-20), 0, 0)},
    60:  {**_LEGS, "spine": (r(30), 0, 0), "chest": (r(20), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    90:  {**_LEGS, "spine": (r(30), 0, 0), "chest": (r(20), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
