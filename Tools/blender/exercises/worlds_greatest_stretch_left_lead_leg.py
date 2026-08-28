"""World's Greatest Stretch (Left Lead Leg) — muscle-body + skin-head animation.

New batch (2026-08-27). "Step the left foot forward into a deep lunge,
drop both hands inside the left foot, then rotate the left arm up and
open the chest to the left." Same half-kneeling lunge + torso-twist +
overhead-reach composition as runners_lunge_with_rotation_left.py — the
two exercises describe the same underlying shape (lunge-with-rotation)
under different names/instructions, so this reuses that proven
composition rather than inventing a new one, with a small forward-hands
beat added at frame 30 before the rotation opens up. Oblique camera per
the same camera/pose-axis coupling reasoning.

Highlight: Left Hip Flexors + Left Hamstrings + Left Adductors + Spinal Erectors.
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
EXERCISE = "worlds_greatest_stretch_left_lead_leg"
VIDEO_NAME = "worlds_greatest_stretch_left_lead_leg.mp4"

CAMERA_AZIMUTH = 45
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['left hip flexor', 'left adductor', 'spinal erector'])

POSES = {
    0:   {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
    30:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
          "spine": (r(10), r(10), 0), "upperarm.R": (r(-40), 0, 0)},
    60:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
          "spine": (r(15), r(32), 0), "chest": (0, r(14), 0),
          "upperarm.L": (r(-150), 0, r(15)), "upperarm.R": (r(-60), 0, 0)},
    90:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
          "spine": (r(15), r(32), 0), "chest": (0, r(14), 0),
          "upperarm.L": (r(-150), 0, r(15)), "upperarm.R": (r(-60), 0, 0)},
    120: {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
}

L.run_seated(globals())
