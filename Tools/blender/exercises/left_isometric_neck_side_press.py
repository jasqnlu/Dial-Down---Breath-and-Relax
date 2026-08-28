"""Left Isometric Neck Side Press — muscle-body + skin-head animation.

Batch 15. "Press your head into your resisting hand so your head doesn't
actually move." A genuinely isometric exercise — literally correct would
be zero head motion, but per suboccipital_release_finger_press.py's
precedent (a "press" cue reads better with a small oscillation implying
effort than a frozen frame), animated a small head local-Z side-bend
oscillation (the same axis the upper-trapezius/scalene family already
proved) rather than a true hold. The resisting hand isn't animated (no
hand-target IK).

Highlight: Left Trapezius + Front Neck, matching the exercise's tags.

**Arm-to-head fix (2026-08-22, animation-vs-instructions audit):** "the
resisting hand isn't animated (no hand-target IK)" above was true but is a
real gap against the instructions ("place your left palm flat against the
left side of your head") — the whole hand-assist neck family shipped with
the assist arm never leaving its resting side. Fixed with numeric FK
instead of true IK: a throwaway probe (`_arm_to_head_probe.py`, kept in
this directory, not part of the shipped pipeline) built just the armature,
posed the head exactly as this script does, and grid-swept `upperarm.L`/
`forearm.L` local-X/Z pairs to minimize the forearm-tail (mitt) distance to
a hand-picked point on the left side of the head cap, above the ear.
Landed within 0.035 world units of the target (the head cap itself is
roughly 0.1-0.15 across, so this reads as the hand touching the head, not
floating near it) at `upperarm.L=(-115,0,10)`, `forearm.L=(-150,0,-30)`.
Own-side arm (own palm to own side of head), unlike the levator-
scapulae/chin-to-shoulder family which uses the OPPOSITE arm.
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
EXERCISE = "left_isometric_neck_side_press"
VIDEO_NAME = "left_isometric_neck_side_press.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left trapezius", "front neck")

# Own-side arm (own palm to own side of head, above the ear) — see
# _arm_to_head_probe.py's numeric fit in the docstring above.
_ARM_UP = {"upperarm.L": (r(-115), 0, r(10)), "forearm.L": (r(-150), 0, r(-30))}
_ARM_MID = {"upperarm.L": (r(-70), 0, r(6)), "forearm.L": (r(-90), 0, r(-18))}

POSES = {
    0:   {},
    30:  {**_ARM_MID, "head": (0, 0, r(-4))},
    60:  {**_ARM_UP, "head": (0, 0, r(-7))},
    90:  {**_ARM_UP, "head": (0, 0, r(-4))},
    120: {},
}

L.run(globals())
