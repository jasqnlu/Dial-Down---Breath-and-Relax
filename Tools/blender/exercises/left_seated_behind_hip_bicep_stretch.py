"""Left Seated Behind-Hip Bicep Stretch — muscle-body + skin-head animation.

Batch 16. "Sit with legs extended, hand planted flat behind the hip,
elbow straight, lean torso slightly forward and away from the hand."
Floor-sitting straight-leg base (`apply_seated_base`, the same `thigh -90,
shin 0` convention as seated_forward_fold.py/left_seated_hamstring_
stretch.py), with the left arm swept behind via `upperarm` local-X
extension (the same "+X = swing back" sign clasped_hands_behind_back.py
established) to plant the straight arm behind the hip, plus a small
forward spine lean ("away from the planted hand").

Highlight: Left Biceps, the muscle named in the exercise itself.
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
EXERCISE = "left_seated_behind_hip_bicep_stretch"
VIDEO_NAME = "left_seated_behind_hip_bicep_stretch.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

WORKED_KEYWORDS = ("left bicep",)

_LEGS = {"thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0),
         "thigh.R": (r(-90), 0, 0), "shin.R": (0, 0, 0)}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "upperarm.L": (r(20), 0, 0)},
    60:  {**_LEGS, "upperarm.L": (r(38), 0, 0), "spine": (r(6), 0, 0)},
    90:  {**_LEGS, "upperarm.L": (r(38), 0, 0), "spine": (r(6), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
