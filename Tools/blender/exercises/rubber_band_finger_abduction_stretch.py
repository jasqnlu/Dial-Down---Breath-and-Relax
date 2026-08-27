"""Rubber Band Finger Abduction Stretch — muscle-body + skin-head animation.

New batch (2026-08-27). "Loop a band around all five fingers near the
tips, spread fingers apart against the resistance, slowly release,
repeat both hands." Same rig limitation as fist_to_fan_tendon_gliding_
flow.py (no finger articulation) — reuses its bilateral forward-hands
setup with a slow forearm spread/release oscillation. Flagged
`animationIsApproximate`.

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
EXERCISE = "rubber_band_finger_abduction_stretch"
VIDEO_NAME = "rubber_band_finger_abduction_stretch.mp4"

CAMERA_AZIMUTH = 20
WORKED_KEYWORDS = (['left forearm', 'right forearm'])

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-65), 0, r(12)), "upperarm.R": (r(-65), 0, r(-12)),
          "forearm.L": (r(-90), 0, r(6)), "forearm.R": (r(-90), 0, r(-6))},
    60:  {"upperarm.L": (r(-65), 0, r(20)), "upperarm.R": (r(-65), 0, r(-20)),
          "forearm.L": (r(-90), 0, r(14)), "forearm.R": (r(-90), 0, r(-14))},
    90:  {"upperarm.L": (r(-65), 0, r(12)), "upperarm.R": (r(-65), 0, r(-12)),
          "forearm.L": (r(-90), 0, r(6)), "forearm.R": (r(-90), 0, r(-6))},
    120: {},
}

L.run(globals())
