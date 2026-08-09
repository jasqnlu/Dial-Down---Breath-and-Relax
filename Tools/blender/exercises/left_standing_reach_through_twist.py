"""Left Standing Reach-Through Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #13. The busiest pose in
the batch: a forward fold, a twist, a cross-body reach and a head turn, all at
once — but every axis involved is individually proven.

Direction — READ THE INSTRUCTIONS, NOT THE NAME. "Left" here names the
DIRECTION ("rotate your torso to the left"), not the side stretched, so the
twist is POSITIVE local-Y (subject's own left, per the corrected convention in
ANIMATION_HANDOFF.md "Twist direction"). The reaching arm is the RIGHT one,
crossing toward the left ankle.

Axes:
  * frame 25 holds the "arms out in a T-shape" setup the instructions open
    with, via symmetric upperarm abduction (local-Z, mirrored signs).
  * spine/chest local-X POSITIVE = forward pitch (the reach toward an ankle is
    as much a fold as a twist), stacked down the chain like
    standing_forward_fold_ragdoll.py.
  * spine/chest local-Y POSITIVE = rotate to the subject's own left.
  * upperarm.R local-X -70 = swing forward and down; local-Z -30 = adduct
    across the midline. Per Gotcha #6 the LEFT arm adducts on +Z, so the RIGHT
    arm's cross-body direction is the mirrored -Z.
  * head local-X +20 / local-Y +20 = "let your gaze follow your right hand",
    looking down and to the left along with the torso.

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
EXERCISE = "left_standing_reach_through_twist"
VIDEO_NAME = "left_standing_reach_through_twist.mp4"

CAMERA_AZIMUTH = 45
# The T-shape widens the silhouette and the fold deepens it; both push past
# the upright rest-pose bounding box the default framing assumes.
ORTHO_SCALE_MULT = 1.55

WORKED_KEYWORDS = ("left oblique", "spinal erector", "lower back")

POSES = {
    0: {},
    25: {
        "upperarm.L": (r(-8), 0, r(-62)),
        "upperarm.R": (r(-8), 0, r(62)),
    },
    60: {
        "spine": (r(30), r(22), 0),
        "chest": (r(15), r(15), 0),
        "upperarm.L": (r(-15), 0, r(-22)),
        "upperarm.R": (r(-60), 0, r(-32)),
        "head": (0, r(22), 0),
    },
    90: {
        "spine": (r(30), r(22), 0),
        "chest": (r(15), r(15), 0),
        "upperarm.L": (r(-15), 0, r(-22)),
        "upperarm.R": (r(-60), 0, r(-32)),
        "head": (0, r(22), 0),
    },
    120: {},
}

L.run(globals())
