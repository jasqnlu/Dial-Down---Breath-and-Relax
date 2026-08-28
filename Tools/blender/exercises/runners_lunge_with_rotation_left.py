"""Runner's Lunge with Rotation (Left) — muscle-body + skin-head animation.

New batch (2026-08-27). "Left foot forward into a deep lunge, back leg
straight and heel lifted; right hand down inside the left foot; left arm
reaches up, chest rotates open to the left." Built on the proven
half-kneeling lunge base (left foot forward = thigh.L=-90/shin.L=90, right
leg back) plus the proven seated-spinal-rotation twist axis (spine/chest
local-Y) and an overhead reach on the lead (left) arm. Oblique 3/4 camera
so both the lunge depth and the torso rotation stay visible (see
ANIMATION_HANDOFF.md's camera/pose-axis coupling note — a pure side or
front view would foreshorten one of the two motions).

Highlight: Left Hip Flexors + Left Obliques.
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
EXERCISE = "runners_lunge_with_rotation_left"
VIDEO_NAME = "runners_lunge_with_rotation_left.mp4"

CAMERA_AZIMUTH = 45
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['left hip flexor', 'left oblique'])

POSES = {
    0:   {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
    30:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
          "spine": (0, r(12), 0), "upperarm.L": (r(-60), 0, r(10))},
    60:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
          "spine": (0, r(28), 0), "chest": (0, r(12), 0),
          "upperarm.L": (r(-150), 0, r(15))},
    90:  {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
          "spine": (0, r(28), 0), "chest": (0, r(12), 0),
          "upperarm.L": (r(-150), 0, r(15))},
    120: {"thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
          "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0)},
}

L.run_seated(globals())
