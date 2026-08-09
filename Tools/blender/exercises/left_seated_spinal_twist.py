"""Left Seated Spinal Twist — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #6. First use of the TWIST axis (local Y) on the
vertical spine/chest bones — every prior exercise in this batch used local-X
(pitch) or local-Z (side bend). Per ANIMATION_HANDOFF.md Gotcha #6, local Y is
a bone's own long axis = twist for any bone regardless of orientation, so this
carries over from the arm bones without a new probe. Camera is angled 45 deg
off front so BOTH shoulders' rotation is visible (a pure front or side view
on an orthographic camera would hide most of a twist's silhouette change).

Rotation-audit update (2026-08-07): originally had no seated pose (legs
stayed in the standing rest pose, reading as a standing torso rotation
despite the name). Added a static seated leg pose — see
ANIMATION_HANDOFF.md's "Rotation audit" section for the probe that validated
thigh -90 / shin +90 local-X as hip-flexion + knee-fold. Held constant
across every keyframe; only the spine/chest twist still varies per frame.
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
EXERCISE = "left_seated_spinal_twist"
VIDEO_NAME = "left_seated_spinal_twist.mp4"

CAMERA_AZIMUTH = 45

WORKED_KEYWORDS = ("left oblique", "spinal erector", "lower back")

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

L.run(globals())
