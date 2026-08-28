"""Seated Spinal Rotation with Overhead Reach (Left) — muscle-body + skin-head.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #11. Combines three
proven pieces: the static seated leg pose, a spine/chest twist, and a large
arm abduction taken all the way overhead.

Direction — READ THE INSTRUCTIONS, NOT THE NAME. This exercise's "(Left)"
names the DIRECTION of travel ("gently rotate your torso to the left"), unlike
the side-bend family where "Left" names the side being stretched. So the twist
here is POSITIVE local-Y, which per the corrected convention
(ANIMATION_HANDOFF.md "Twist direction") rotates toward the subject's own
left. The left arm is the one reaching overhead.

Axes:
  * thigh/shin = the static seated pose (thigh -90 / shin +90), held at every
    keyframe. This exercise is genuinely seated ("Sit tall on a chair or the
    floor") and CAMERA_AZIMUTH 45 is far enough off-front for the folded legs
    to read properly — at azimuth 0 the camera looks straight down the thigh
    and it collapses into an unreadable blob.
  * upperarm.L local-Z -155 = abduction carried past horizontal to overhead.
    This is by far the largest arm rotation attempted on this rig; see the
    risk note in left_wall_corner_pec_stretch.py, which doubles here.
  * spine/chest local-Y POSITIVE = rotate to the subject's own left.
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
EXERCISE = "seated_spinal_rotation_overhead_reach_left"
VIDEO_NAME = "seated_spinal_rotation_overhead_reach_left.mp4"

CAMERA_AZIMUTH = 45
# The overhead reach pushes the silhouette well above the rest-pose bounding
# box, the same framing problem standing_forward_fold_ragdoll.py hit downward.
ORTHO_SCALE_MULT = 1.45

WORKED_KEYWORDS = ("left oblique", "left lats", "spinal erector")

# Static seated leg pose, held constant across every keyframe.
_SEATED = {
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
}

POSES = {
    0: dict(_SEATED),
    30: {
        **_SEATED,
        "upperarm.L": (r(-80), 0, 0),
        "spine": (0, r(10), 0),
    },
    60: {
        **_SEATED,
        "upperarm.L": (r(-150), 0, 0),
        "spine": (0, r(28), 0),
        "chest": (0, r(12), 0),
    },
    90: {
        **_SEATED,
        "upperarm.L": (r(-150), 0, 0),
        "spine": (0, r(28), 0),
        "chest": (0, r(12), 0),
    },
    120: dict(_SEATED),
}

L.run_seated(globals())
