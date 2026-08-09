"""Seated Neck Rotation — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #1. Pure `head` local-Y
twist — the simplest possible use of the twist axis, on a single bone.

Two things differ from every earlier script:
  * BOTH directions in one clip. The exercise turns right, returns to center,
    then turns left (it is not a bilateral L/R pair — one seed exercise covers
    both sides), so POSES traces a 9-keyframe path instead of the usual
    neutral -> peak -> hold -> neutral arc.
  * PEAK_FRAME is therefore overridden. `_lib.run()` renders its "peak" still
    and logs the sanity tail-position at PEAK_FRAME, which defaults to 60 —
    but frame 60 is the *neutral* pass-through here, so the still would show
    nothing. 35 is the right-turn hold.

Camera is front-on: a head twist swings the face from face-on to profile,
which is the most legible silhouette change a front camera can show. (Per the
third batch's gotcha, don't trust the tail-position log for a twist-only pose —
a bone rotating about its own long axis barely moves its tail. Verified from
the rendered PNGs instead.)

NOT rendered seated, despite the name. The static seated leg pose (thigh -90 /
shin +90) is proven and was applied here first, but it only reads correctly
from azimuth 45+: the thigh points along world -Y, so a near-front camera
looks straight down its long axis and the leg foreshortens into an
unreadable blob. The camera angle here is chosen for head legibility, and
sitting is incidental to a neck stretch (unlike the seated spinal twists,
where bracing against folded legs is what isolates the spine). This also
keeps the whole neck family consistent — neck_flexion_chin_to_chest,
neck_extension_look_up and chin_tuck_forward_head_reset all render standing.
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
EXERCISE = "seated_neck_rotation"
VIDEO_NAME = "seated_neck_rotation.mp4"

CAMERA_AZIMUTH = 0
PEAK_FRAME = 35

# The atlas has no sided neck groups (only Back Neck / Front Neck), and a
# rotation works both sides across the clip — highlight the whole neck.
WORKED_KEYWORDS = ("back neck", "front neck")

# Positive local-Y turns the head toward the subject's own right (same sign
# convention as the seated spinal twists).
POSES = {
    0: {},
    20: {"head": (0, r(30), 0)},
    35: {"head": (0, r(55), 0)},
    50: {"head": (0, r(55), 0)},
    65: {},
    80: {"head": (0, r(-55), 0)},
    95: {"head": (0, r(-55), 0)},
    110: {"head": (0, r(-30), 0)},
    120: {},
}

L.run(globals())
