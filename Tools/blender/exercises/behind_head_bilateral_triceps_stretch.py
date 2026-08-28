"""Behind-Head Bilateral Triceps Stretch — muscle-body + skin-head animation.

Bilateral version of the overhead-triceps family (left/right_
overhead_triceps_stretch.py) — both hands drop behind the head instead of
just one. Pitch (local-X) is sagittal and carries no side, so both arms use
the exact same render-verified numbers as the single-arm scripts
(`upperarm -160, forearm -150`, whose angles add into one total rotation
per Gotcha #6). Fingers interlacing isn't animated (no hand-target IK).

Highlight: Left Triceps + Right Triceps.
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
EXERCISE = "behind_head_bilateral_triceps_stretch"
VIDEO_NAME = "behind_head_bilateral_triceps_stretch.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left tricep", "right tricep")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0), "upperarm.R": (r(-90), 0, 0),
          "forearm.L": (r(-60), 0, 0), "forearm.R": (r(-60), 0, 0)},
    60:  {"upperarm.L": (r(-160), 0, 0), "upperarm.R": (r(-160), 0, 0),
          "forearm.L": (r(-150), 0, 0), "forearm.R": (r(-150), 0, 0)},
    90:  {"upperarm.L": (r(-160), 0, 0), "upperarm.R": (r(-160), 0, 0),
          "forearm.L": (r(-150), 0, 0), "forearm.R": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
