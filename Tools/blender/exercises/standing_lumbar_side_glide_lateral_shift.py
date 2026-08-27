"""Standing Lumbar Side Glide (Lateral Shift) — muscle-body + skin-head animation.

New batch (2026-08-27). "Shift your hips directly to one side without
bending or twisting, keeping shoulders level, then glide back and shift
to the other side." A true lateral pelvis TRANSLATION isn't available on
this rig (only rotation between bone segments) — approximated with a
small `spine` local-Z side-bend, the closest available proxy, alternating
left and right. Flagged `animationIsApproximate` since the real motion is
a shift, not a bend.

Highlight: Spinal Erectors + Lower Back.
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
EXERCISE = "standing_lumbar_side_glide_lateral_shift"
VIDEO_NAME = "standing_lumbar_side_glide_lateral_shift.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = (['spinal erector', 'lower back'])

POSES = {
    0:   {},
    30:  {"spine": (0, 0, r(10))},
    60:  {},
    90:  {"spine": (0, 0, r(-10))},
    120: {},
}

L.run(globals())
