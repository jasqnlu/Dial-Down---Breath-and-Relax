"""Standing IT Band Side Stretch (Left) — muscle-body + skin-head animation.

Batch 14. "Cross your left leg behind your right, reach your left arm
overhead, lean your torso to the right, push your left hip out." The
torso-bend-and-overhead-reach half of this is mechanically identical to
the already-shipped left_standing_side_reach.py (same bend direction: a
LEFT-named stretch bending the torso right) — reused verbatim, with the
LEFT thigh given a small constant cross-behind angle (adduction plus a
touch of hip extension, the same small-magnitude combination already
proven safe individually in the cross-body and tibialis-toe-point poses)
held through the whole clip.

Highlight: Left Quadriceps + Left Hip Flexors, matching the exercise's
tags. Flagged `animationIsApproximate` (the leg-cross is a small angle
approximation, not literal ankle contact).
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
EXERCISE = "standing_it_band_side_stretch_left"
VIDEO_NAME = "standing_it_band_side_stretch_left.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left quadricep", "left hip flexor")

_CROSS = {"thigh.L": (r(8), 0, r(10))}

POSES = {
    0: {**_CROSS},
    30: {
        **_CROSS,
        "spine": (0, 0, r(12)),
        "chest": (0, 0, r(10)),
        "upperarm.L": (r(-70), 0, 0),
    },
    60: {
        **_CROSS,
        "spine": (0, 0, r(26)),
        "chest": (0, 0, r(20)),
        "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0),
    },
    90: {
        **_CROSS,
        "spine": (0, 0, r(26)),
        "chest": (0, 0, r(20)),
        "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0),
    },
    120: {**_CROSS},
}

L.run(globals())
