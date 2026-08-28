"""Left Standing Reach-Through Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #13. The busiest pose in
the batch: a forward fold, a twist, a cross-body reach and a head turn, all at
once.

Direction — READ THE INSTRUCTIONS, NOT THE NAME. "Left" here names the
DIRECTION ("rotate your torso to the left"), not the side stretched, so the
twist is POSITIVE local-Y (subject's own left, per the corrected convention in
ANIMATION_HANDOFF.md "Twist direction"). The reaching arm is the RIGHT one,
crossing toward the left ankle.

SHIPPED 2026-08-09, on the second attempt (see ANIMATION_HANDOFF.md's
"Reach-through twist, second attempt" section for the full story). Deferred
2026-08-08 after three passes tried to make the reach cross the midline via
`upperarm` local-Z ADDUCTION — that's the axis already documented to collide
with the torso (arms-down source mesh, no clearance), and it never read as
travelling across the body no matter the camera. The fix wasn't a bigger
twist or a different angle on the same axis — it was dropping local-Z
entirely. The reaching arm here uses ONLY local-X flexion (deep, -140,
already proven safe up to -150 elsewhere), and lets the `chest`/`spine`
TWIST (35+20 degrees of local-Y, well past the shallow 8-15 degree twists
used elsewhere) carry the shoulder — and the arm hanging from it — across
the body instead. No local-Z on the reaching arm at all.

Axes:
  * frame 25 holds the "arms out in a T-shape" setup, via symmetric
    upperarm abduction (local-Z, mirrored signs, kept at a SAFE magnitude
    -45/+45 rather than a literal 90 — see the supine spinal twist's
    docstring for the same tearing tradeoff at 85+ degrees).
  * spine/chest local-X POSITIVE = forward pitch (the reach toward an ankle
    is as much a fold as a twist), stacked down the chain like
    standing_forward_fold_ragdoll.py.
  * spine/chest local-Y POSITIVE = rotate to the subject's own left — this
    is what carries the reaching arm across, not the arm's own rotation.
  * upperarm.R local-X -140, local-Z 0 — pure flexion, no adduction.
  * head local-X +20 / local-Y +20 = "let your gaze follow your right
    hand", looking down and to the left along with the torso.
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
# The T-shape widens the silhouette and the fold+twist deepens it well past
# the upright rest-pose bounding box the default framing assumes.
ORTHO_SCALE_MULT = 1.6

WORKED_KEYWORDS = ("left oblique", "spinal erector", "lower back")

POSES = {
    0: {},
    25: {
        "upperarm.L": (r(-8), 0, r(-45)),
        "upperarm.R": (r(-8), 0, r(45)),
    },
    60: {
        "spine": (r(45), r(35), 0),
        "chest": (r(20), r(20), 0),
        "upperarm.L": (r(-8), 0, r(-45)),
        "upperarm.R": (r(-140), 0, 0),
        "head": (r(20), r(20), 0),
    },
    90: {
        "spine": (r(45), r(35), 0),
        "chest": (r(20), r(20), 0),
        "upperarm.L": (r(-8), 0, r(-45)),
        "upperarm.R": (r(-140), 0, 0),
        "head": (r(20), r(20), 0),
    },
    120: {},
}

L.run(globals())
