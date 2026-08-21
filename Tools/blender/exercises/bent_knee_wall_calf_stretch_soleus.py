"""Bent-Knee Wall Calf Stretch (Soleus) — muscle-body + skin-head animation.

Batch 14. Same staggered wall-lean shape as
calf_stretch_at_wall_straight_knee.py, but "step back CLOSER than the
straight-knee version, bend BOTH knees slightly" — smaller hip-extension
angle on the back leg (it's closer, not fully lunged back) plus a small
`shin` bend added to the back leg (previously kept straight), and a
smaller front-knee bend too.

Highlight: both Calves.
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
EXERCISE = "bent_knee_wall_calf_stretch_soleus"
VIDEO_NAME = "bent_knee_wall_calf_stretch_soleus.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("calve",)

POSES = {
    0:   {},
    30:  {"thigh.R": (r(6), 0, 0), "thigh.L": (r(-6), 0, 0),
          "upperarm.L": (r(-40), 0, 0), "upperarm.R": (r(-40), 0, 0)},
    60:  {"thigh.R": (r(10), 0, 0), "shin.R": (r(-12), 0, 0),
          "thigh.L": (r(-12), 0, 0), "shin.L": (r(20), 0, 0),
          "spine": (r(6), 0, 0),
          "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    90:  {"thigh.R": (r(10), 0, 0), "shin.R": (r(-12), 0, 0),
          "thigh.L": (r(-12), 0, 0), "shin.L": (r(20), 0, 0),
          "spine": (r(6), 0, 0),
          "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    120: {},
}

L.run(globals())
