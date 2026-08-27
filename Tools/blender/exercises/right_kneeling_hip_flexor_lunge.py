"""Right Kneeling Hip-Flexor Lunge — muscle-body + skin-head animation.

60-exercise batch. NEW base composition: half-kneeling lunge (front foot planted, rear knee down) — see half_kneel_legs note in this generator / the handoff doc. Right knee down (rear), left foot planted forward. Torso stays upright per the instructions ("keep your torso upright rather than leaning forward") — only a tiny forward `spine` tuck for "shift your weight forward".

Highlight: Right Hip Flexors.
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
EXERCISE = "right_kneeling_hip_flexor_lunge"
VIDEO_NAME = "right_kneeling_hip_flexor_lunge.mp4"

WORKED_KEYWORDS = ("right hip",)

_LEGS = {
    "thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
    "thigh.L": (r(15), 0, 0), "shin.L": (r(100), 0, 0),
}

CAMERA_AZIMUTH = -100
ORTHO_SCALE_MULT = 1.4
SEATED_DROP = 0.50

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(4), 0, 0)},
    60:  {**_LEGS, "spine": (r(8), 0, 0)},
    90:  {**_LEGS, "spine": (r(8), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
