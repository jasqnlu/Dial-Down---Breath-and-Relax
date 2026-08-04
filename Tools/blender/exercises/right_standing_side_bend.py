"""Right Standing Side Bend — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third batch, exercise #3. Mirror of left_standing_side_bend.py: that script
established positive local-Z bends the torso toward the subject's own right
(renders leaning screen-left). "Right Standing Side Bend" stretches the RIGHT
flank, so the bend goes the other way — NEGATIVE local-Z — and only "Right
Obliques" (the side actually stretched) is highlighted. Same magnitudes,
opposite sign, mirrored front camera.
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
EXERCISE = "right_standing_side_bend"
VIDEO_NAME = "right_standing_side_bend.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("right oblique",)

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(-12)),
        "chest": (0, 0, r(-10)),
    },
    60: {
        "spine": (0, 0, r(-28)),
        "chest": (0, 0, r(-22)),
        "head": (0, 0, r(-8)),
    },
    90: {
        "spine": (0, 0, r(-28)),
        "chest": (0, 0, r(-22)),
        "head": (0, 0, r(-8)),
    },
    120: {},
}

L.run(globals())
