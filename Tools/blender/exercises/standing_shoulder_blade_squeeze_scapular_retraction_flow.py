"""Standing Shoulder Blade Squeeze (Scapular Retraction Flow) — muscle-body + skin-head animation.

60-exercise batch. Bilateral squeeze-and-release; approximated as a small bilateral `upperarm` local-Z adduction pulling both elbows slightly back/together (the same direction as scapular retraction even though the scapulae themselves can't be animated). No scapula/clavicle bone exists on this rig, so the true mechanism (shoulder-blade motion) can't be shown directly; approximated via a small proxy motion on the nearest available bone. Flagged animationIsApproximate.

Highlight: Left Trapezius, Right Trapezius.
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
EXERCISE = "standing_shoulder_blade_squeeze_scapular_retraction_flow"
VIDEO_NAME = "standing_shoulder_blade_squeeze_scapular_retraction_flow.mp4"

WORKED_KEYWORDS = ("trapezius",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    20:  {"upperarm.L": (0, 0, r(-12)), "upperarm.R": (0, 0, r(12))},
    30:  {},
    50:  {"upperarm.L": (0, 0, r(-12)), "upperarm.R": (0, 0, r(12))},
    60:  {},
    90:  {},
    120: {},
}

L.run(globals())
