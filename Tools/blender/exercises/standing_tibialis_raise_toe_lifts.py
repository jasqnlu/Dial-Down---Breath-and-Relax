"""Standing Tibialis Raise (Toe Lifts) — muscle-body + skin-head animation.

New batch (2026-08-27). "Heels planted, lift the balls of the feet and
toes up as high as possible, hold, lower with control." No independent
ankle/toe joint on this rig (same limitation documented across the whole
ankle/shin family in ANIMATION_HANDOFF.md) — approximated via a small
bilateral `shin` backward tilt (the only available shin-local motion)
standing in for the toes lifting. Flagged `animationIsApproximate`.

Highlight: both Tibialis.
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
EXERCISE = "standing_tibialis_raise_toe_lifts"
VIDEO_NAME = "standing_tibialis_raise_toe_lifts.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = (['left tibialis', 'right tibialis'])

POSES = {
    0:   {},
    30:  {"shin.L": (r(-8), 0, 0), "shin.R": (r(-8), 0, 0)},
    60:  {"shin.L": (r(-14), 0, 0), "shin.R": (r(-14), 0, 0)},
    90:  {"shin.L": (r(-8), 0, 0), "shin.R": (r(-8), 0, 0)},
    120: {},
}

L.run(globals())
