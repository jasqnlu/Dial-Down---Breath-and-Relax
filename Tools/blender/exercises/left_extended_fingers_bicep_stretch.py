"""Left Extended-Fingers Bicep Stretch — muscle-body + skin-head animation.

Batch 11. "Extend your arm out to the side at shoulder height, palm up,
fingers spread, extend the wrist so fingers point toward the floor behind
you." Straight-arm abduction to shoulder height (local-Z, the same axis as
left_wall_corner_pec_stretch.py, kept at a similar magnitude — 55 deg,
below that script's own largest angle) plus a forearm local-Y twist toward
supination (palm up, same device used for the wrist-flexor family). The
wrist extension itself can't be shown (rigid hand mitt, no wrist joint).

Highlight: Left Biceps + Left Forearm, matching the exercise's tags.
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
EXERCISE = "left_extended_fingers_bicep_stretch"
VIDEO_NAME = "left_extended_fingers_bicep_stretch.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left bicep", "left forearm")

POSES = {
    0:   {},
    30:  {"upperarm.L": (0, 0, r(-30)), "forearm.L": (0, r(45), 0)},
    60:  {"upperarm.L": (0, 0, r(-55)), "forearm.L": (0, r(90), 0)},
    90:  {"upperarm.L": (0, 0, r(-55)), "forearm.L": (0, r(90), 0)},
    120: {},
}

L.run(globals())
