"""Left Wall Bicep Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #9. Reuses the arm-bone convention from
clasped_hands_behind_back_muscleonly.py (+X on upperarm = swing back / shoulder
extension) but only on ONE side, with the elbow kept nearly straight (a small
-5 deg forearm angle, not the deep -28 deg fold used for the clasp) — the wall
stretch extends the whole arm back and pins the hand on a wall behind, rather
than folding the forearm to clasp the other hand.

Rotation-audit fix: the shipped v1 of this script never rotated the torso,
even though the exercise's own instructions are "slowly rotate your torso
away from the wall." Added a chest/spine local-Y twist, shallower than a
dedicated twist exercise (15/8 deg vs. the seated twist's 35/10) since this
is a secondary component of a bicep stretch.

Sign correction (2026-08-08): the first pass at this fix used POSITIVE local-Y
on the belief — inherited from ANIMATION_HANDOFF.md — that +Y twists toward the
subject's own right. A numeric probe (`_twist_probe.py`, see the handoff doc's
"Twist direction" section) proved the opposite: +Y twists toward the subject's
own LEFT. The wall is behind the LEFT arm here, so "rotate away from the wall"
means rotating RIGHT, which is NEGATIVE local-Y. Signs flipped accordingly.
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
EXERCISE = "left_wall_bicep_stretch"
VIDEO_NAME = "left_wall_bicep_stretch.mp4"

# Side view (arm side toward camera) shows the backward reach silhouette.
CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left bicep",)

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(20), 0, 0),
        "chest": (0, r(-8), 0),
    },
    60: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(-15), 0),
        "spine": (0, r(-8), 0),
    },
    90: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(-15), 0),
        "spine": (0, r(-8), 0),
    },
    120: {},
}

L.run(globals())
