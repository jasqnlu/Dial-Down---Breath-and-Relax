"""Hanging Lat Stretch on Bar or Ledge — muscle-body + skin-head animation.

60-exercise batch. Standing, both arms overhead deep flexion (reusing the overhead-triceps -160 range) plus a small forward `spine` sag (gravity lengthening the lats/upper back) for "allow your body weight to gently lengthen both lats."

Highlight: Left Lats, Right Lats.
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
EXERCISE = "hanging_lat_stretch_on_bar_or_ledge"
VIDEO_NAME = "hanging_lat_stretch_on_bar_or_ledge.mp4"

WORKED_KEYWORDS = ("lat",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-100), 0, 0), "upperarm.R": (r(-100), 0, 0)},
    60:  {"upperarm.L": (r(-160), 0, 0), "upperarm.R": (r(-160), 0, 0), "spine": (r(6), 0, 0)},
    90:  {"upperarm.L": (r(-160), 0, 0), "upperarm.R": (r(-160), 0, 0), "spine": (r(6), 0, 0)},
    120: {},
}

L.run(globals())
