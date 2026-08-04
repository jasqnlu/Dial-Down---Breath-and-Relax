"""Standing Back Extension — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #4. Uses the same forward-pitch axis confirmed in
neck_flexion_chin_to_chest.py / standing_forward_fold_ragdoll.py (positive
local-X on a vertical bone pitches it toward -Y world / forward) but with the
NEGATIVE sign — arching the spine/chest backward instead of folding forward.
Kept to a modest 20-30 deg (vs. the 75 deg forward fold) since this is a
gentle standing extension, not a deep backbend; arms are left untouched
(they naturally trail slightly behind, which reads fine at this magnitude).
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
EXERCISE = "standing_back_extension"
VIDEO_NAME = "standing_back_extension.mp4"

# Side view shows the backward arch silhouette; a front view would foreshorten it.
CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("abs", "lower back", "spinal erector")

POSES = {
    0: {},
    30: {
        "spine": (r(-10), 0, 0),
        "chest": (r(-7), 0, 0),
    },
    60: {
        "spine": (r(-20), 0, 0),
        "chest": (r(-15), 0, 0),
        "head": (r(-10), 0, 0),
    },
    90: {
        "spine": (r(-20), 0, 0),
        "chest": (r(-15), 0, 0),
        "head": (r(-10), 0, 0),
    },
    120: {},
}

L.run(globals())
