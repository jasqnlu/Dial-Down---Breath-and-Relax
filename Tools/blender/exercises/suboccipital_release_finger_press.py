"""Suboccipital Release (Finger Press) — muscle-body + skin-head animation.

Sixth batch, exercise #1. "Slowly nod your chin down and up a few times" —
the same solved forward-pitch axis as neck_flexion_chin_to_chest.py /
chin_tuck_forward_head_reset.py, but REPEATED across the loop (down, up,
down) rather than a single hold, since the instruction explicitly calls for
a repeated small nod rather than one held stretch. Magnitude sits between
the two references — deeper than the chin tuck's 14 deg (this is a real nod,
not a retraction) but shallower than the full chin-to-chest 30 deg (light,
rhythmic, under finger pressure, not a deep stretch).

Not seated/lying despite the instructions offering both — same reasoning as
the rest of the neck family (rendered standing keeps the family visually
consistent; sitting/lying is incidental to a neck motion, per
left_chin_to_shoulder_diagonal_stretch.py's docstring).

The "hands behind head, fingers pressing" detail is not animated (arms stay
at rest) — same simplification as the isometric neck press exercises: this
rig has no way to land a hand precisely on the back of the skull without a
hand-target IK the pipeline doesn't have, and the head nod is the visible,
worked motion anyway.

Highlight: Back Neck — the suboccipital muscles aren't their own atlas
group; Back Neck is the same stand-in the chin-to-chest/chin-tuck family
uses.
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
EXERCISE = "suboccipital_release_finger_press"
VIDEO_NAME = "suboccipital_release_finger_press.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("back neck",)

# The rhythmic down-up-down motion means frame 60 (the default PEAK_FRAME
# used for the static preview render) lands on a NEUTRAL keyframe here, not
# a nodded one — the baked video still plays the full repeated nod
# correctly either way, but a nodded preview thumbnail is more
# representative of the exercise.
PEAK_FRAME = 30

POSES = {
    0:   {},
    30:  {"head": (r(20), 0, 0)},
    60:  {},
    90:  {"head": (r(20), 0, 0)},
    120: {},
}

L.run(globals())
