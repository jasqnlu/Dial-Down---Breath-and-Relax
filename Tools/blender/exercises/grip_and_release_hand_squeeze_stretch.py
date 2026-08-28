"""Grip and Release (Hand Squeeze Stretch) — muscle-body + skin-head animation.

New batch (2026-08-27). "Hold both hands out, squeeze into fists, hold,
release and spread fingers wide, repeat." Same rig limitation as
fist_to_fan_tendon_gliding_flow.py (no finger articulation) — reuses its
bilateral forward-hands setup, with the forearm oscillation standing in
for the squeeze-and-release cycle. Flagged `animationIsApproximate`.

Highlight: both Forearm (Hand-only target tags can't highlight the mitt itself).
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
EXERCISE = "grip_and_release_hand_squeeze_stretch"
VIDEO_NAME = "grip_and_release_hand_squeeze_stretch.mp4"

CAMERA_AZIMUTH = 20
WORKED_KEYWORDS = (['left forearm', 'right forearm'])

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-65), 0, r(15)), "upperarm.R": (r(-65), 0, r(-15)),
          "forearm.L": (r(-95), 0, r(8)), "forearm.R": (r(-95), 0, r(-8))},
    60:  {"upperarm.L": (r(-65), 0, r(15)), "upperarm.R": (r(-65), 0, r(-15)),
          "forearm.L": (r(-95), r(18), r(8)), "forearm.R": (r(-95), r(-18), r(-8))},
    90:  {"upperarm.L": (r(-65), 0, r(15)), "upperarm.R": (r(-65), 0, r(-15)),
          "forearm.L": (r(-95), 0, r(8)), "forearm.R": (r(-95), 0, r(-8))},
    120: {},
}

L.run(globals())
