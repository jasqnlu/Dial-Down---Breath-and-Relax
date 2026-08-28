"""Right Wall Bicep Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #10. Mirror of left_wall_bicep_stretch.py, using the R
arm bones instead of L (no Z-axis mirroring needed — Gotcha #6's "+X = swing
back" sign applies identically to both sides; only the adduction Z axis,
unused here, would need flipping). Camera is on the opposite side (270 deg)
so the working arm faces the lens.

Rotation-audit fix: same missing-torso-twist bug as left_wall_bicep_stretch.py
(pre-fix) — added chest/spine local-Y twist, mirrored (negative Y = twist
left, matching right_seated_spinal_twist.py's sign) since rotating away from
a wall behind the RIGHT arm means twisting left.

Twist-direction correction (2026-08-08): mirror of the sign fix applied to its
L/R partner — see that script's docstring and ANIMATION_HANDOFF.md's "Twist
direction" section. +Y local-Y rotates toward the subject's own LEFT, not
right as the handoff doc previously claimed.
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
EXERCISE = "right_wall_bicep_stretch"
VIDEO_NAME = "right_wall_bicep_stretch.mp4"

CAMERA_AZIMUTH = 270

WORKED_KEYWORDS = ("right bicep",)

POSES = {
    0: {},
    30: {
        "upperarm.R": (r(20), 0, 0),
        "chest": (0, r(8), 0),
    },
    60: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(15), 0),
        "spine": (0, r(8), 0),
    },
    90: {
        "upperarm.R": (r(45), 0, 0),
        "forearm.R": (r(-5), 0, 0),
        "chest": (0, r(15), 0),
        "spine": (0, r(8), 0),
    },
    120: {},
}

L.run(globals())
