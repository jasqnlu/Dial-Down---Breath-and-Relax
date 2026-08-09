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
away from the wall." Added a chest/spine local-Y twist reusing the seated
spinal twist's proven sign convention (positive Y = twist right) — rotating
away from a wall behind the LEFT arm means twisting right, same direction as
`left_seated_spinal_twist.py`, just a shallower peak angle (15/8 deg vs.
35/10) since this is a secondary component of a bicep stretch, not a
dedicated twist.
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
        "chest": (0, r(8), 0),
    },
    60: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(15), 0),
        "spine": (0, r(8), 0),
    },
    90: {
        "upperarm.L": (r(45), 0, 0),
        "forearm.L": (r(-5), 0, 0),
        "chest": (0, r(15), 0),
        "spine": (0, r(8), 0),
    },
    120: {},
}

L.run(globals())
