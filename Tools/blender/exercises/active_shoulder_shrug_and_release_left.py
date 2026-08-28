"""Active Shoulder Shrug & Release (Left) — muscle-body + skin-head animation.

60-exercise batch. Shrugging the shoulder toward the ear has no scapula/clavicle bone to animate on this rig; approximated as a small `chest` local-Z tilt raising the left side of the ribcage/shoulder, held then released, matching the contract-and-release rhythm. No scapula/clavicle bone exists on this rig, so the true mechanism (shoulder-blade motion) can't be shown directly; approximated via a small proxy motion on the nearest available bone. Flagged animationIsApproximate.

Highlight: Left Trapezius, Left Shoulder.
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
EXERCISE = "active_shoulder_shrug_and_release_left"
VIDEO_NAME = "active_shoulder_shrug_and_release_left.mp4"

WORKED_KEYWORDS = ("left trapezius",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    20:  {"chest": (0, 0, r(10))},
    30:  {},
    50:  {"chest": (0, 0, r(10))},
    60:  {},
    90:  {},
    120: {},
}

L.run(globals())
