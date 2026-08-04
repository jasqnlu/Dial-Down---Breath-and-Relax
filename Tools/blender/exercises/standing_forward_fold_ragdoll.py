"""Standing Forward Fold (Ragdoll) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Second of the second batch — builds on `_lib.py` and the forward-pitch axis
convention confirmed in neck_flexion_chin_to_chest.py (positive local-X on a
vertical bone pitches it forward, toward -Y world). The hip hinge here is
just the SAME rotation stacked on spine + chest (both children down the
`hips -> spine -> chest` chain), so the whole torso folds forward from the
hips while the legs stay planted.

Arms: the instructions say "let your head, neck, and arms hang heavy" — i.e.
the arms should stay WORLD-vertical (hang straight down under gravity), not
swing forward pinned to the folding chest. Because `upperarm.{L,R}` are
children of `chest`, and every pose rotation here is about local X (which
stays parallel to world X through the whole parent chain — pitching about X
doesn't change what "X" means), the chest's total world pitch is simply
spine + chest local rotations added together. Giving the upperarms the
NEGATIVE of that sum cancels the inherited parent pitch exactly, so they hang
vertical regardless of how far the torso folds.
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
EXERCISE = "standing_forward_fold_ragdoll"
VIDEO_NAME = "standing_forward_fold_ragdoll.mp4"

# Side view shows the hip-hinge silhouette (the whole point of this stretch);
# a front view would foreshorten the fold into almost nothing.
CAMERA_AZIMUTH = 90

# The peak fold extends the silhouette far beyond the standing rest bounds on
# the depth axis (head swings out to y~-0.76 vs. a ~1.9-tall rest bounding
# box) — one static camera has to frame both ends of the loop, so widen well
# past the default rest-pose-sized framing.
ORTHO_SCALE_MULT = 1.7

WORKED_KEYWORDS = ("lower back", "spinal erector", "hamstring")

_SPINE_30, _CHEST_30 = 20, 15          # ramp: torso pitch so far = 35 deg
_SPINE_60, _CHEST_60 = 45, 30          # peak: torso pitch so far = 75 deg

POSES = {
    0: {},
    30: {
        "spine": (r(_SPINE_30), 0, 0),
        "chest": (r(_CHEST_30), 0, 0),
        "upperarm.L": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
        "upperarm.R": (r(-(_SPINE_30 + _CHEST_30)), 0, 0),
    },
    60: {
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    90: {
        "spine": (r(_SPINE_60), 0, 0),
        "chest": (r(_CHEST_60), 0, 0),
        "head": (r(10), 0, 0),
        "upperarm.L": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
        "upperarm.R": (r(-(_SPINE_60 + _CHEST_60)), 0, 0),
    },
    120: {},
}

L.run(globals())
