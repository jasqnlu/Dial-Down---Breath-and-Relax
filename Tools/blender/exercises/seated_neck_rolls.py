"""Seated Neck Rolls — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #2. No new axis: this is
the proven `head` local-X (pitch) and local-Z (side bend) combined across many
keyframes to trace a circular path, rather than a single-axis hold.

The exercise's own instruction — "Avoid rolling the head all the way back;
keep the motion in front" — is why the path never goes to negative X. It
sweeps right ear -> chin down -> left ear entirely through the front
hemisphere, then reverses ("Reverse direction after a few slow half-circles"),
closing the loop back at neutral.

PEAK_FRAME = 45 (chin-down, the deepest point of the arc) so the peak still
render catches an actual pose rather than a mid-transition frame.

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
EXERCISE = "seated_neck_rolls"
VIDEO_NAME = "seated_neck_rolls.mp4"

# Slightly off-front so the chin-down portion of the circle reads as motion
# rather than pure foreshortening, while keeping the ear-to-shoulder tilts
# (the widest part of the arc) clearly visible.
CAMERA_AZIMUTH = 20
PEAK_FRAME = 45

WORKED_KEYWORDS = ("back neck", "front neck")

# +Z tilts toward the subject's own right, +X pitches the chin down.
POSES = {
    0: {},
    15: {"head": (0, 0, r(22))},
    30: {"head": (r(18), 0, r(15))},
    45: {"head": (r(35), 0, 0)},
    60: {"head": (r(18), 0, r(-15))},
    75: {"head": (0, 0, r(-22))},
    90: {"head": (r(18), 0, r(-15))},
    105: {"head": (r(35), 0, 0)},
    120: {},
}

L.run(globals())
