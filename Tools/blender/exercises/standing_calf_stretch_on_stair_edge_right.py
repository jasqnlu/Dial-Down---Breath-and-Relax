"""Standing Calf Stretch on Stair Edge (Right) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Same pose as the left version (torso sway is symmetric, no L/R skeletal difference); highlight follows the named side.

Highlight: Right Calves.
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
EXERCISE = "standing_calf_stretch_on_stair_edge_right"
VIDEO_NAME = "standing_calf_stretch_on_stair_edge_right.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = ("right calve",)

POSES = {
    0:   {},
    30:  {"spine": (r(3), 0, 0)},
    60:  {"spine": (r(6), 0, 0)},
    90:  {"spine": (r(3), 0, 0)},
    120: {},
}

L.run(globals())
