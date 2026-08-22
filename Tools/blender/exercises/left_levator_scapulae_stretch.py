"""Left Levator Scapulae Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fifth batch, exercise #1. Same two-axis combination as
left_chin_to_shoulder_diagonal_stretch.py (local-X pitch + local-Y twist),
just re-weighted: this instruction calls for a BIGGER turn (45 deg, explicit
in the text) and a SMALLER tuck ("tuck your chin slightly") than the
diagonal stretch's near-even split, so X stays modest while Y goes larger.

Instruction: "turn your head about 45 degrees to the RIGHT... tuck your chin
slightly and look down toward your right armpit" — a LEFT-named stretch
turning right, same bilateral-naming convention already established
(Left Standing Side Bend bends right, Left Chin-to-Shoulder Diagonal turns
right) — the name is the side being STRETCHED, not the direction of travel.
+X pitches the chin down (proven). For the turn, -Y = toward the subject's
own right — NOT the +Y the chin-to-shoulder-diagonal docstrings claimed.
Verified numerically here with a throwaway probe (`_head_twist_probe.py`,
scratchpad): posed `head` local-Y=+30 in isolation and tracked which side of
the head-skin cap moved toward the front camera (world -Y). The side at
world -X (the subject's RIGHT, per the established "+X = subject's own
left" fact) moved to -Y (forward) under +Y — i.e. +Y turns the head toward
the subject's own LEFT, the same sign the chest/spine twist family already
uses (see ANIMATION_HANDOFF.md's "Twist direction" section) — the head bone
was never actually an exception, it just never got re-checked after that
fix. This means left_chin_to_shoulder_diagonal_stretch.py,
right_chin_to_shoulder_diagonal_stretch.py, left_scalene_neck_stretch.py and
right_scalene_neck_stretch.py were shipped turning backwards; fixed
alongside this script (see ANIMATION_HANDOFF.md).

Highlight: no "levator scapulae" group in the atlas — Back Neck (the nod/tuck
component) + Left Trapezius (the side being stretched) is the same pairing
left_chin_to_shoulder_diagonal_stretch uses for the same reason.

**Arm-to-head fix (2026-08-22, animation-vs-instructions audit):** the
instructions call for the OPPOSITE hand ("rest your right hand on top of
your head") — arms previously stayed at rest. Fixed with the same numeric
FK approach as left_isometric_neck_side_press.py's fix (see that script's
docstring): `_arm_to_head_probe.py` swept `upperarm.R`/`forearm.R` against
this script's own peak head pose and landed within 0.048 world units of
the head-bone tail (the top-of-head target) at `upperarm.R=(-130,0,30)`,
`forearm.R=(-100,0,-30)`.
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
EXERCISE = "left_levator_scapulae_stretch"
VIDEO_NAME = "left_levator_scapulae_stretch.mp4"

# 45 deg off front shows both the turn and the tuck — same reasoning as the
# chin-to-shoulder diagonal script.
CAMERA_AZIMUTH = 45

WORKED_KEYWORDS = ("back neck", "left trapezius")

# Opposite-side arm (right hand rests on top of the head) — see
# _arm_to_head_probe.py's numeric fit in the docstring above.
_ARM_UP = {"upperarm.R": (r(-130), 0, r(30)), "forearm.R": (r(-100), 0, r(-30))}
_ARM_MID = {"upperarm.R": (r(-80), 0, r(18)), "forearm.R": (r(-60), 0, r(-18))}

POSES = {
    0: {},
    30: {**_ARM_MID, "head": (r(8), r(-25), 0)},
    60: {**_ARM_UP, "head": (r(14), r(-45), 0)},
    90: {**_ARM_UP, "head": (r(14), r(-45), 0)},
    120: {},
}

L.run(globals())
