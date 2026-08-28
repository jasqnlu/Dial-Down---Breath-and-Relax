"""Left Standing Side Reach — muscle-body + skin-head animation.

Seventh batch, exercise #5. Combines left_standing_side_bend.py's proven
torso side-bend (local-Z on spine/chest — see that script's docstring for
the sign derivation: POSITIVE bends the subject's own RIGHT) with an
overhead arm reach (local-X on upperarm, the same deep-flexion convention
used by the overhead reach family). "Raise your LEFT arm overhead and reach
up and over to the RIGHT" — a LEFT-named stretch bending right, the same
bilateral convention as the side-bend family (name = side stretched, not
direction of travel). `upperarm.L` gets pure local-X (no local-Z) — it
inherits the chest's rightward bend automatically as a child bone, so no
extra adduction is needed (and adduction is the axis documented to tear).

Highlight: Left Obliques + Left Lats, matching the exercise's target tags
("side body from hip to fingertips").
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
EXERCISE = "left_standing_side_reach"
VIDEO_NAME = "left_standing_side_reach.mp4"

# Front view reads the lateral C-curve best, same as the side-bend family.
CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left oblique", "left lats")

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(12)),
        "chest": (0, 0, r(10)),
        "upperarm.L": (r(-70), 0, 0),
    },
    60: {
        "spine": (0, 0, r(26)),
        "chest": (0, 0, r(20)),
        "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0),
    },
    90: {
        "spine": (0, 0, r(26)),
        "chest": (0, 0, r(20)),
        "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0),
    },
    120: {},
}

L.run(globals())
