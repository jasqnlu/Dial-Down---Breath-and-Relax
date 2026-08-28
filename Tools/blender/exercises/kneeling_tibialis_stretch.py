"""Kneeling Tibialis Stretch — muscle-body + skin-head animation.

Batch 13. "Kneel upright, tops of feet flat, slowly sit back onto your
heels, torso upright." Kneeling seated base (`apply_seated_base`, the same
`thigh -75 / shin +90` sit-back fold childs_pose.py and the chair-sit
exercises use), but the torso stays UPRIGHT (no forward spine/chest fold)
— the only new script in this family to keep the torso vertical over a
kneeling base, since the exercise is entirely about the shin angle, not a
back stretch. The actual foot-top-flat-on-the-floor detail can't be shown
(no independent ankle joint on this rig), so the stretch reads through the
kneeling silhouette and the shin highlight alone.

Highlight: both Tibialis, matching the exercise's tags.
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
EXERCISE = "kneeling_tibialis_stretch"
VIDEO_NAME = "kneeling_tibialis_stretch.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("tibialis",)

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS},
    60:  {**_LEGS},
    90:  {**_LEGS},
    120: {**_LEGS},
}

L.run_seated(globals())
