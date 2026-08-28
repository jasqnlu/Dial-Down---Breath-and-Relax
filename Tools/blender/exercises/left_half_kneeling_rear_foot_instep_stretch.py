"""Left Half-Kneeling Rear-Foot Instep Stretch — muscle-body + skin-head animation.

New batch (2026-08-27). "Half-kneeling lunge, working-side leg back, knee
on the floor; flatten the top of the back foot; sink hips down and
slightly forward." Reuses the proven half-kneeling lunge base
(SEATED_DROP=0.50, see left_kneeling_hip_flexor_lunge.py) verbatim — left
leg back (thigh=+15/shin=+100), right foot planted forward — adding a
small extra rear-thigh extension + forward spine tuck for "sink hips
forward." No independent ankle/toe joint, so the "flatten the back foot"
detail isn't modeled; flagged `animationIsApproximate`.

Highlight: Left Tibialis.
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
EXERCISE = "left_half_kneeling_rear_foot_instep_stretch"
VIDEO_NAME = "left_half_kneeling_rear_foot_instep_stretch.mp4"

CAMERA_AZIMUTH = 100
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50
WORKED_KEYWORDS = (['left tibialis'])

POSES = {
    0:   {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
    30:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0), "spine": (r(3), 0, 0)},
    60:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(20), 0, 0), "shin.L": (r(100), 0, 0), "spine": (r(6), 0, 0)},
    90:  {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(20), 0, 0), "shin.L": (r(100), 0, 0), "spine": (r(6), 0, 0)},
    120: {"thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
          "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0)},
}

L.run_seated(globals())
