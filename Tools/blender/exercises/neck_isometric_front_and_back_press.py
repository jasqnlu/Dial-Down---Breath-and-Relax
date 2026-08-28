"""Neck Isometric Front-and-Back Press — muscle-body + skin-head animation.

20-exercise thin-coverage batch. "Press your head forward into your palm
without letting it actually move, hold, release, then press backward into a
hand behind your head." Genuinely isometric like left_isometric_neck_side_
press.py — per that script's precedent, a "press" cue reads better with a
small oscillation implying effort than a frozen frame. Uses the same head
local-X pitch axis as neck_flexion_chin_to_chest.py (forward) and neck_
extension_look_up.py (backward), alternating between the two rather than
holding one direction. No hand-target IK for either assisting hand (same
simplification as suboccipital_release_finger_press.py) — the head motion
is the visible, worked part of the exercise.

Highlight: Front Neck + Back Neck, matching the exercise's tags.
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
EXERCISE = "neck_isometric_front_and_back_press"
VIDEO_NAME = "neck_isometric_front_and_back_press.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("front neck", "back neck")

POSES = {
    0:   {},
    30:  {"head": (r(15), 0, 0)},
    60:  {},
    90:  {"head": (r(-12), 0, 0)},
    120: {},
}

L.run(globals())
