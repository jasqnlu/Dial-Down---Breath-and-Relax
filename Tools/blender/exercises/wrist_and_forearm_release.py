"""Wrist & Forearm Release — muscle-body + skin-head animation.

Batch 4 hand/wrist follow-up. "Extend your right arm in front of you and
gently pull back on your fingers to stretch the wrist and forearm. Switch
to stretch the fingers downward for the opposite side of the forearm."
Combines both twist directions used by the flexor/extensor family into one
loop on a single representative arm (the exercise's own `isBilateral:
false` already implies a "switch sides" cue in the app, so the demo shows
one arm's full flexor-then-extensor cycle rather than trying to show both
arms and both directions at once). No hand-target IK for the pulling hand.
Flagged `animationIsApproximate`.

Highlight: Right Forearm.
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
EXERCISE = "wrist_and_forearm_release"
VIDEO_NAME = "wrist_and_forearm_release.mp4"

CAMERA_AZIMUTH = -90

WORKED_KEYWORDS = ("right forearm",)

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (0, r(-90), 0)},
    60:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (0, r(90), 0)},
    90:  {"upperarm.R": (r(-90), 0, 0), "forearm.R": (0, r(90), 0)},
    120: {},
}

L.run(globals())
