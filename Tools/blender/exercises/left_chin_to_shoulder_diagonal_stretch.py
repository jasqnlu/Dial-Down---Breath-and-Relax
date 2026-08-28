"""Left Chin-to-Shoulder Diagonal Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #3. First script to
COMBINE two head axes in a single pose: local-X (pitch, proven by
neck_flexion_chin_to_chest.py) and local-Y (twist, proven by the seated spinal
twists). Each axis is individually validated; combining them is new, so the
render is eyeballed rather than trusted from the tail-position log.

Instruction: "turn your chin diagonally down toward your RIGHT armpit" — so a
LEFT-named stretch turns the head to the subject's own right while nodding
down (+X). That matches the app's bilateral naming convention, where
"Left <stretch>" means the LEFT side is the side being stretched, not the
direction of travel (same as Left Standing Side Bend, which bends right).

**Sign correction (2026-08-20):** originally shipped with +Y for "turn
right," on the belief the head bone's twist sign was independent of the
chest/spine convention. A numeric probe
(left_levator_scapulae_stretch.py's `_head_twist_probe.py`) proved the head
bone follows the SAME "+Y = subject's own left" convention already
documented for chest/spine (ANIMATION_HANDOFF.md's "Twist direction"
section) — it was never actually an exception, it just never got re-checked
after that fix landed. Turning right is -Y, not +Y; corrected here.

Highlight: the atlas has no sided neck groups (only Back Neck / Front Neck),
so the side-specific part of the highlight comes from Left Trapezius, which
pairs with "the back-left of your neck" in the exercise's own instructions.

**Arm-to-head fix (2026-08-22, animation-vs-instructions audit):** "Rest
your right hand gently on top of your head" — arms previously stayed at
rest. Same numeric FK fix as left_isometric_neck_side_press.py /
left_levator_scapulae_stretch.py (see the isometric script's docstring for
the method): `_arm_to_head_probe.py` swept `upperarm.R`/`forearm.R`
against this script's own peak head pose and landed within 0.026 world
units of the head-bone tail at `upperarm.R=(-110,0,30)`,
`forearm.R=(-110,0,-30)`.

NOT rendered seated, despite the name. The static seated leg pose (thigh -90 /
shin +90) is proven and was applied here first, but it only reads correctly
from azimuth 45+: the thigh points along world -Y, so a near-front camera
looks straight down its long axis and the leg foreshortens into an
unreadable blob. The camera angle here is chosen for head legibility, and
sitting is incidental to a neck stretch (unlike the seated spinal twists,
where bracing against folded legs is what isolates the spine). This also
keeps the whole neck family consistent — neck_flexion_chin_to_chest,
neck_extension_look_up and chin_tuck_forward_head_reset all render standing.
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
EXERCISE = "left_chin_to_shoulder_diagonal_stretch"
VIDEO_NAME = "left_chin_to_shoulder_diagonal_stretch.mp4"

# 45 deg off front shows both components of the diagonal — a pure front view
# hides the nod, a pure side view hides the turn.
CAMERA_AZIMUTH = 45

WORKED_KEYWORDS = ("back neck", "left trapezius")

_ARM_UP = {"upperarm.R": (r(-100), 0, r(25)), "forearm.R": (r(-95), 0, r(-25))}
_ARM_MID = {"upperarm.R": (r(-60), 0, r(15)), "forearm.R": (r(-58), 0, r(-15))}

POSES = {
    0: {},
    30: {**_ARM_MID, "head": (r(15), r(-20), 0)},
    60: {**_ARM_UP, "head": (r(30), r(-40), 0)},
    90: {**_ARM_UP, "head": (r(30), r(-40), 0)},
    120: {},
}

L.run(globals())
