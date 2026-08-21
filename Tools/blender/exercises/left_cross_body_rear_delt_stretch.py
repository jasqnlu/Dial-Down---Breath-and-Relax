"""Left Cross-Body Rear Delt Stretch — muscle-body + skin-head animation.

Batch 11 (session push toward 130 exercises). "Bring your arm straight
across your chest at shoulder height, other forearm presses it closer."
Horizontal adduction at shoulder height — a new combination for this rig:
prior cross-body motions (Standing Reach-Through Twist) worked around
adduction entirely because they reach DOWN across the body, where the arm
sweeps away from the torso surface into open space and drags a "cape" of
skin (Gotcha #2). This motion is different: the arm stays at shoulder
height, swinging INTO the region directly in front of the chest that's
already Euclidean-close to the arm bone at rest, so the torso-bleed
mechanism that tears an OUTWARD swing shouldn't apply. Kept the adduction
moderate (60 deg) rather than testing the limit. The "other forearm
presses" detail isn't animated (no hand-target IK, same as the rest of the
family).

Highlight: Left Shoulder (posterior deltoid, the muscle named in the
exercise itself).
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
EXERCISE = "left_cross_body_rear_delt_stretch"
VIDEO_NAME = "left_cross_body_rear_delt_stretch.mp4"

# Front view shows the arm sweeping across the chest most clearly.
CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left shoulder",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-40), 0, r(20))},
    60:  {"upperarm.L": (r(-75), 0, r(35))},
    90:  {"upperarm.L": (r(-75), 0, r(35))},
    120: {},
}

L.run(globals())
