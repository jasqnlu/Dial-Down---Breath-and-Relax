"""Right Chin-to-Shoulder Diagonal Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #4. Mirror of
left_chin_to_shoulder_diagonal_stretch.py — see that script's docstring for
the axis reasoning. Chin turns toward the LEFT armpit here (+Y, corrected
2026-08-20 — see the left script's docstring for the sign-correction
derivation) while nodding down (+X, unmirrored: pitch is in the sagittal
plane and has no side).

Only the twist axis flips sign between the pair. Per the third batch's gotcha,
confirm the two renders are genuinely mirrored rather than identical by
eyeballing the PNGs — a twist barely moves the bone tail, so the sanity log
cannot tell them apart.

**Arm-to-head fix (2026-08-22, animation-vs-instructions audit):** mirror
of left_chin_to_shoulder_diagonal_stretch.py's fix — "rest your left hand
on top of your head" — `upperarm.L=(-110,0,-30)`, `forearm.L=(-110,0,30)`
(flipped local-Z from the left script's `upperarm.R`/`forearm.R`).
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
EXERCISE = "right_chin_to_shoulder_diagonal_stretch"
VIDEO_NAME = "right_chin_to_shoulder_diagonal_stretch.mp4"

CAMERA_AZIMUTH = -45

WORKED_KEYWORDS = ("back neck", "right trapezius")

_ARM_UP = {"upperarm.L": (r(-100), 0, r(-25)), "forearm.L": (r(-95), 0, r(25))}
_ARM_MID = {"upperarm.L": (r(-60), 0, r(-15)), "forearm.L": (r(-58), 0, r(15))}

POSES = {
    0: {},
    30: {**_ARM_MID, "head": (r(15), r(20), 0)},
    60: {**_ARM_UP, "head": (r(30), r(40), 0)},
    90: {**_ARM_UP, "head": (r(30), r(40), 0)},
    120: {},
}

L.run(globals())
