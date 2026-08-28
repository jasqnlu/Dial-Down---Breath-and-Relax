"""Prayer Stretch (Palms Together, Lower) — muscle-body + skin-head
animation.

Sixth batch, exercise #2. Instructions: palms together at chest, THEN
lower toward the waist to deepen the stretch — so the REST frame is hands
high at the chest (prayer start) and the PEAK/stretch frame is hands lower
at the waist, the opposite ordering from most of this family (where 0 is
neutral-arms-down and the peak is the deepest reach).

Both forearms use the proven `-X = elbow flexion` sign (Gotcha #6): a big
flexion keeps the forearm folded up with the hand near the chest (frame 0),
a smaller flexion angle lets the forearm swing down so the hand drops to
waist height (peak). `upperarm` stays at a small constant forward flexion
(elbows drift slightly in front of the torso, matching "in front of your
chest") — never touched by local-Z, so this avoids the arm-abduction tearing
failure mode entirely.

First attempt used the SAME forearm local-Z angle (~10 deg) at both the
flexed-up and extended-down keyframes to pull the hands toward the midline
("palms together"). Rendered with the hands together at the chest (frame 0)
but splayed visibly apart at the waist (peak) — a fixed angular offset
closes a smaller gap when the forearm is folded short (hand close to the
elbow) than when it's extended long (same angle, longer lever arm, bigger
linear gap). Fixed by scaling the Z angle up as the forearm extends
(9->28 deg from chest to waist) instead of holding it constant, so the
hands stay together through the whole lowering motion, not just at the top.

Highlight: WORKED_KEYWORDS = ("forearm",) — both sides; the instructions
target "the underside of both forearms and wrists" symmetrically.
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
EXERCISE = "prayer_stretch_palms_together_lower"
VIDEO_NAME = "prayer_stretch_palms_together_lower.mp4"

CAMERA_AZIMUTH = 20

WORKED_KEYWORDS = ("forearm",)

_UPPER = {
    "upperarm.L": (r(14), 0, r(6)),
    "upperarm.R": (r(14), 0, r(-6)),
}

POSES = {
    0:   {**_UPPER, "forearm.L": (r(-95), 0, r(9)),  "forearm.R": (r(-95), 0, r(-9))},
    30:  {**_UPPER, "forearm.L": (r(-75), 0, r(16)), "forearm.R": (r(-75), 0, r(-16))},
    60:  {**_UPPER, "forearm.L": (r(-45), 0, r(28)), "forearm.R": (r(-45), 0, r(-28))},
    90:  {**_UPPER, "forearm.L": (r(-45), 0, r(28)), "forearm.R": (r(-45), 0, r(-28))},
    120: {**_UPPER, "forearm.L": (r(-95), 0, r(9)),  "forearm.R": (r(-95), 0, r(-9))},
}

L.run(globals())
