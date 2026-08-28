"""Calf Stretch at Wall (Straight-Knee) — muscle-body + skin-head animation.

Batch 14. "Hands flat against a wall at shoulder height, step the right
foot back into a lunge, back knee straight, heel down, lean toward the
wall." First staggered-stance pose on this rig: the back leg reuses the
small hip-extension angle proven by left_standing_tibialis_stretch_toe_
point.py (kept straight, `shin` at 0), the front leg gets a small hip
flexion, and both arms press forward at shoulder height (moderate
`upperarm` flexion, well short of the overhead-reach magnitudes already
proven safe) standing in for hands on the wall. A small forward chest/
spine lean completes "lean toward the wall."

Highlight: both Calves, matching the exercise's tags.
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
EXERCISE = "calf_stretch_at_wall_straight_knee"
VIDEO_NAME = "calf_stretch_at_wall_straight_knee.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("calve",)

POSES = {
    0:   {},
    30:  {"thigh.R": (r(10), 0, 0), "thigh.L": (r(-8), 0, 0),
          "upperarm.L": (r(-40), 0, 0), "upperarm.R": (r(-40), 0, 0)},
    60:  {"thigh.R": (r(18), 0, 0), "thigh.L": (r(-15), 0, 0),
          "spine": (r(8), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0)},
    90:  {"thigh.R": (r(18), 0, 0), "thigh.L": (r(-15), 0, 0),
          "spine": (r(8), 0, 0),
          "upperarm.L": (r(-75), 0, 0), "upperarm.R": (r(-75), 0, 0)},
    120: {},
}

L.run(globals())
