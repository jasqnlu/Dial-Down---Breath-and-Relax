"""Left Seated Figure-Four Stretch — muscle-body + skin-head animation.

Batch 12 (session push toward 130 exercises). Chair-sitting base
(`apply_seated_base`, same bent-knee `thigh -75 / shin +90` fold the seated
spinal twists use for "feet flat on the floor"), with the LEFT thigh given
extra external-rotation abduction (local-Z) to open the bent knee out to
the side, approximating "cross your left ankle over your right knee." A
literal ankle-on-knee contact (like the supine Figure-4's shin swing) isn't
attempted here — the seated base pose's hip fold is already large (-75)
and stacking a big shin cross on top of it risks the same hip-crease/mitt
issues the supine Figure-4 needed a dedicated pipeline fix for; opening the
thigh out reads as the recognizable "4" shape without that risk. Forward
torso lean added on top, matching "lean your torso forward."

Highlight: Left Glutes, the muscle named in the exercise itself.
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
EXERCISE = "left_seated_figure_four_stretch"
VIDEO_NAME = "left_seated_figure_four_stretch.mp4"

CAMERA_AZIMUTH = 20
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left glutes",)

_LEGS_REST = {
    "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS_REST},
    30:  {**_LEGS_REST, "thigh.L": (r(-75), 0, r(-20))},
    60:  {**_LEGS_REST, "thigh.L": (r(-75), 0, r(-38)),
          "spine": (r(12), 0, 0), "chest": (r(8), 0, 0)},
    90:  {**_LEGS_REST, "thigh.L": (r(-75), 0, r(-38)),
          "spine": (r(12), 0, 0), "chest": (r(8), 0, 0)},
    120: {**_LEGS_REST},
}

L.run_seated(globals())
