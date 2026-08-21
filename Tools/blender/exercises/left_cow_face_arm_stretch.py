"""Left Cow-Face Arm Stretch — muscle-body + skin-head animation.

Eighth batch, exercise #3. Combines two already-solved arm poses on
opposite arms at once — the first exercise to do that. LEFT arm reuses
left_overhead_triceps_stretch.py's exact solved combination (`upperarm -160,
forearm -150`, which drops the hand behind the head/upper back — see that
script's docstring for the derivation). RIGHT arm reuses
clasped_hands_behind_back_muscleonly.py's solved behind-the-lower-back reach
(`upperarm +28, forearm -34`, adducted toward the midline). Each half was
independently proven on its own bone chain with no shared geometry, so
combining them was low-risk — rendered and checked for any new interaction
(e.g. torso muscles double-claimed by both arms' joint-blend weighting) that
neither half hit alone; none found.

Highlight: Left Triceps + Left Shoulder, matching the exercise's target
tags (the working/overhead arm, not the anchoring arm behind the back).
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
EXERCISE = "left_cow_face_arm_stretch"
VIDEO_NAME = "left_cow_face_arm_stretch.mp4"

CAMERA_AZIMUTH = 45

WORKED_KEYWORDS = ("left tricep", "left shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0),  "forearm.L": (r(-60), 0, 0),
          "upperarm.R": (r(14), 0, r(-6)), "forearm.R": (r(-18), 0, r(-11))},
    60:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0),
          "upperarm.R": (r(28), 0, r(-12)), "forearm.R": (r(-34), 0, r(-22))},
    90:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0),
          "upperarm.R": (r(28), 0, r(-12)), "forearm.R": (r(-34), 0, r(-22))},
    120: {},
}

L.run(globals())
