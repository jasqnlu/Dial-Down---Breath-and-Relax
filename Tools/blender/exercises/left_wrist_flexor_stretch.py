"""Left Wrist Flexor Stretch — muscle-body + skin-head animation.

Batch 10 (session push toward 130 exercises). "Extend your arm in front of
you, palm up, use the other hand to pull the fingers back." This rig has
no wrist/finger articulation (the hand is a rigid convex-hull "mitt" bound
100% to the forearm bone — see ANIMATION_HANDOFF.md's rigid_weight note),
so the actual finger-pull can't be shown. Approximation: extend the arm
forward at chest height (upperarm local-X flexion, the proven "-X =
forward" convention) and twist the forearm to a supinated (palm-up)
orientation via local-Y — the one degree of freedom this rig genuinely has
that reads as "palm up." No hand-target IK for the pulling hand.
Flagged `animationIsApproximate` in SeedData.

Highlight: Left Forearm, the muscle named in the exercise's own tags.
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
EXERCISE = "left_wrist_flexor_stretch"
VIDEO_NAME = "left_wrist_flexor_stretch.mp4"

# Side view reads the forward-extended arm silhouette + forearm twist best.
CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left forearm",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-45), 0, 0), "forearm.L": (0, r(45), 0)},
    60:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (0, r(90), 0)},
    90:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (0, r(90), 0)},
    120: {},
}

L.run(globals())
