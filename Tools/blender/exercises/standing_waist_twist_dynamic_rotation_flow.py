"""Standing Waist Twist (Dynamic Rotation Flow) — muscle-body + skin-head animation.

New batch (2026-08-27). "Feet hip-width, knees soft, arms relaxed and
swinging loosely; rotate the torso side to side, letting the arms swing
naturally." Bilateral version of the spine/chest local-Y twist axis
proven in seated_spinal_rotation_overhead_reach_*.py, but standing and
with both arms swinging loosely (following the twist via a small
opposite-phase local-Z) instead of one arm reaching overhead.

Highlight: both Obliques + Lower Spine.
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
EXERCISE = "standing_waist_twist_dynamic_rotation_flow"
VIDEO_NAME = "standing_waist_twist_dynamic_rotation_flow.mp4"

CAMERA_AZIMUTH = 20
WORKED_KEYWORDS = (['oblique', 'lower spine'])

POSES = {
    0:   {},
    30:  {"spine": (0, r(18), 0), "chest": (0, r(8), 0),
          "upperarm.L": (0, 0, r(-10)), "upperarm.R": (0, 0, r(10))},
    60:  {"spine": (0, r(-18), 0), "chest": (0, r(-8), 0),
          "upperarm.L": (0, 0, r(10)), "upperarm.R": (0, 0, r(-10))},
    90:  {"spine": (0, r(18), 0), "chest": (0, r(8), 0),
          "upperarm.L": (0, 0, r(-10)), "upperarm.R": (0, 0, r(10))},
    120: {},
}

L.run(globals())
