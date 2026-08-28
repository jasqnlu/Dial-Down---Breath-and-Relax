"""Right Seated Spinal Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #7. Mirror of left_seated_spinal_twist.py — same twist
magnitudes, opposite local-Y sign, highlighting the right-side muscles instead.

Rotation-audit update (2026-08-07): added the same static seated leg pose as
left_seated_spinal_twist.py (thigh -90 / shin +90 local-X, no L/R sign flip
needed — hip flexion is straight-forward, not lateral). See
ANIMATION_HANDOFF.md's "Rotation audit" section.

Twist-direction correction (2026-08-08): mirror of the sign fix applied to its
L/R partner — see that script's docstring and ANIMATION_HANDOFF.md's "Twist
direction" section. +Y local-Y rotates toward the subject's own LEFT, not
right as the handoff doc previously claimed.
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
EXERCISE = "right_seated_spinal_twist"
VIDEO_NAME = "right_seated_spinal_twist.mp4"

CAMERA_AZIMUTH = 45

WORKED_KEYWORDS = ("right oblique", "spinal erector", "lower back")

# Static seated leg pose (see ANIMATION_HANDOFF.md "Rotation audit"), held
# constant across every keyframe.
_SEATED = {
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
}

POSES = {
    0: dict(_SEATED),
    30: {**_SEATED, "spine": (0, r(15), 0)},
    60: {
        **_SEATED,
        "spine": (0, r(35), 0),
        "chest": (0, r(10), 0),
    },
    90: {
        **_SEATED,
        "spine": (0, r(35), 0),
        "chest": (0, r(10), 0),
    },
    120: dict(_SEATED),
}

L.run_seated(globals())
