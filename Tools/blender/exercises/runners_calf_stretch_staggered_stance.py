"""Runner's Calf Stretch (Staggered Stance) — muscle-body + skin-head animation.

Batch 14. Same staggered wall-lean family as
calf_stretch_at_wall_straight_knee.py (right foot back, straight, both
heels down, front knee bends, lean into the wall) — kept the back leg's
hip-extension and straight shin identical to that script (the instructions
are nearly the same "straight back leg" cue), with a deeper front-knee
bend and lean to visually distinguish the two near-duplicate exercises.

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
EXERCISE = "runners_calf_stretch_staggered_stance"
VIDEO_NAME = "runners_calf_stretch_staggered_stance.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("calve",)

POSES = {
    0:   {},
    30:  {"thigh.R": (r(10), 0, 0), "thigh.L": (r(-12), 0, 0), "shin.L": (r(15), 0, 0),
          "upperarm.L": (r(-40), 0, 0), "upperarm.R": (r(-40), 0, 0)},
    60:  {"thigh.R": (r(18), 0, 0), "thigh.L": (r(-22), 0, 0), "shin.L": (r(30), 0, 0),
          "spine": (r(8), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0)},
    90:  {"thigh.R": (r(18), 0, 0), "thigh.L": (r(-22), 0, 0), "shin.L": (r(30), 0, 0),
          "spine": (r(8), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0)},
    120: {},
}

L.run(globals())
