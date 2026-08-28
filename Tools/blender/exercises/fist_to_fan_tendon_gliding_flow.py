"""Fist-to-Fan Tendon Gliding Flow — muscle-body + skin-head animation.

20-exercise thin-coverage batch, hand family. "Start with both hands in
loose fists, slowly open your fingers and spread them wide like a fan, hold,
then curl back into a fist." No finger articulation on this rig — same
honest-limit approximation as hook_fist_tendon_glide.py, whose "hands up in
front of you" arm position matches this exercise's implied setup closely
enough to reuse directly (bilateral, both arms raised forward at chest
height, forearm oscillating as the only available degree of freedom so the
loop reads as active rather than frozen).

Highlight: both Forearm (Hand-only target tags can't highlight the mitt
itself). Flagged `animationIsApproximate`.
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
EXERCISE = "fist_to_fan_tendon_gliding_flow"
VIDEO_NAME = "fist_to_fan_tendon_gliding_flow.mp4"

CAMERA_AZIMUTH = 20

WORKED_KEYWORDS = ("left forearm", "right forearm")

_UPPER = {"upperarm.L": (r(-65), 0, r(15)), "upperarm.R": (r(-65), 0, r(-15))}

POSES = {
    0:   {},
    30:  {**_UPPER, "forearm.L": (r(-95), 0, r(8)), "forearm.R": (r(-95), 0, r(-8))},
    60:  {**_UPPER, "forearm.L": (r(-95), r(18), r(8)),  "forearm.R": (r(-95), r(-18), r(-8))},
    90:  {**_UPPER, "forearm.L": (r(-95), r(18), r(8)),  "forearm.R": (r(-95), r(-18), r(-8))},
    120: {},
}

L.run(globals())
