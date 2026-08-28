"""Right Overhead Triceps Stretch — muscle-body + skin-head animation.

Mirror of left_overhead_triceps_stretch.py — see that script's docstring
for the full pose derivation (upperarm/forearm local-X angles add into one
total rotation about the same fixed world axis; `upperarm -160, forearm
-150` was the render-verified combination that drops the hand behind the
head rather than reaching straight up). Pitch (local-X) is sagittal and has
no side, so both bones use the exact same numbers as the left script — only
the arm (`.R`) and highlight side change.

Highlight: Right Triceps.
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
EXERCISE = "right_overhead_triceps_stretch"
VIDEO_NAME = "right_overhead_triceps_stretch.mp4"

# Side view from the opposite side so the stretched (right) arm faces camera.
CAMERA_AZIMUTH = 270

WORKED_KEYWORDS = ("right tricep",)

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (r(-60), 0, 0)},
    60:  {"upperarm.R": (r(-160), 0, 0), "forearm.R": (r(-150), 0, 0)},
    90:  {"upperarm.R": (r(-160), 0, 0), "forearm.R": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
