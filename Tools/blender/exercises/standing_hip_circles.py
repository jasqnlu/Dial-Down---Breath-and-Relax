"""Standing Hip Circles — muscle-body + skin-head animation.

New batch (2026-08-27). "Stand on one leg, trace slow circles with the
other knee/hip." Combines the proven thigh local-X (flexion) and
local-Z (abduction) axes across the 4 keyframes into a rough circular
path — the same lazy-circle 4-key idea proven for wrist_circles.py and
shoulder_pendulum_swing, applied to the hip. Kept to conservative angles
(well under the standing-abduction ceiling documented in standing_
adductor_rock_side_to_side.py) since this is a weight-bearing standing
leg tracing a genuinely new combined path.

Kept conservative for a weight-bearing standing leg tracing a new combined path; flagged `animationIsApproximate`.

Highlight: both Hip Flexors + both Adductors.
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
EXERCISE = "standing_hip_circles"
VIDEO_NAME = "standing_hip_circles.mp4"

CAMERA_AZIMUTH = 20
ORTHO_SCALE_MULT = 1.25
WORKED_KEYWORDS = (['hip flexor', 'adductor'])

POSES = {
    0:   {},
    30:  {"thigh.R": (r(-20), 0, r(12))},
    60:  {"thigh.R": (r(10), 0, r(18))},
    90:  {"thigh.R": (r(10), 0, r(-14))},
    120: {},
}

L.run(globals())
