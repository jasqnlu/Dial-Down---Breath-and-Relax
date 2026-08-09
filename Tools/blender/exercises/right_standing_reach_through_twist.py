"""Right Standing Reach-Through Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #14. Mirror of
left_standing_reach_through_twist.py — see that script's docstring for the
full axis derivation, including why "Right" names the direction of rotation
rather than the side stretched. The reaching arm here is the LEFT one.

Mirrored: spine/chest local-Y (twist), upperarm local-Z (abduction and
cross-body adduction), head local-Y (gaze).
NOT mirrored: spine/chest/head local-X (forward pitch) and upperarm local-X
(forward swing) — both sagittal, no side.

NOT SHIPPED (deferred 2026-08-08). Kept for the next session rather than
deleted, because the twist/fold half of the pose is sound — what fails is the
cross-body reach. Three authoring passes could not make the reaching arm
read as travelling ACROSS the body toward the opposite ankle: from any camera
that shows the twist, the arm reads as hanging or swinging outward instead.
Additionally the first pass buried the head skin cap inside the chest at ~91
deg of cumulative forward pitch (spine 45 + chest 26 + head 20) — eased to 45
deg total here, which fixed the head but left the reach ambiguous.

Probable root cause: reaching across the midline needs the upper arm to both
flex forward and adduct past the body's centre line, and adduction (local-Z
toward the midline) collides with the torso because the source mesh is modeled
arms-down with no clearance. Likely needs either a dedicated numeric probe for
cross-body adduction, or an accepted approximation, before shipping.
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
ORTHO_SCALE_MULT = 1.55

WORKED_KEYWORDS = ("right oblique", "spinal erector", "lower back")

POSES = {
    0: {},
    25: {
        "upperarm.L": (r(-8), 0, r(-62)),
        "upperarm.R": (r(-8), 0, r(62)),
    },
    60: {
        "spine": (r(30), r(-22), 0),
        "chest": (r(15), r(-15), 0),
        "upperarm.R": (r(-15), 0, r(22)),
        "upperarm.L": (r(-60), 0, r(32)),
        "head": (0, r(-22), 0),
    },
    90: {
        "spine": (r(30), r(-22), 0),
        "chest": (r(15), r(-15), 0),
        "upperarm.R": (r(-15), 0, r(22)),
        "upperarm.L": (r(-60), 0, r(32)),
        "head": (0, r(-22), 0),
    },
    120: {},
}

L.run(globals())
