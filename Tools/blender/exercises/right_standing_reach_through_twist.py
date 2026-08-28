"""Right Standing Reach-Through Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #14. Mirror of
left_standing_reach_through_twist.py — see that script's docstring for the
full derivation, including why "Right" names the direction of rotation
rather than the side stretched, and why the reach uses ONLY local-X flexion
on the reaching arm (no local-Z adduction, which is what collided with the
torso in three earlier failed passes). The reaching arm here is the LEFT one.

Mirrored: spine/chest local-Y (twist), upperarm local-Z (T-shape abduction
only — the reaching arm has no Z component), head local-Y (gaze).
NOT mirrored: spine/chest/head local-X (forward pitch) and upperarm local-X
(forward swing) — both sagittal, no side.

SHIPPED 2026-08-09 (see the left script's docstring for the fix that
unblocked both).
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
EXERCISE = "right_standing_reach_through_twist"
VIDEO_NAME = "right_standing_reach_through_twist.mp4"

CAMERA_AZIMUTH = 315
ORTHO_SCALE_MULT = 1.6

WORKED_KEYWORDS = ("right oblique", "spinal erector", "lower back")

POSES = {
    0: {},
    25: {
        "upperarm.L": (r(-8), 0, r(-45)),
        "upperarm.R": (r(-8), 0, r(45)),
    },
    60: {
        "spine": (r(45), r(-35), 0),
        "chest": (r(20), r(-20), 0),
        "upperarm.R": (r(-8), 0, r(45)),
        "upperarm.L": (r(-140), 0, 0),
        "head": (r(20), r(-20), 0),
    },
    90: {
        "spine": (r(45), r(-35), 0),
        "chest": (r(20), r(-20), 0),
        "upperarm.R": (r(-8), 0, r(45)),
        "upperarm.L": (r(-140), 0, 0),
        "head": (r(20), r(-20), 0),
    },
    120: {},
}

L.run(globals())
