"""Left Standing Side Bend — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Third of the second batch — builds on `_lib.py`. Uses local-Z instead of local-X on the vertical spine/chest bones. A probe
run (see ANIMATION_HANDOFF.md's "Second batch" section) showed +20 deg
local-Z moves a vertical bone's tail toward world -X. A second probe
(rendering red/blue marker cubes through the actual front camera) confirmed
world -X renders on **screen-left**, and -X is also where the real
"Right"-tagged muscle meshes physically sit (Left Obliques centroid
x=+0.13, Right Obliques x=-0.13) — so +X is the subject's actual left side,
and a front camera view mirrors left/right like facing someone directly.
Net effect: **positive local-Z bends the torso toward the subject's own
RIGHT** (renders leaning screen-left) — confirmed in the rendered peak frame
(head/shoulders visibly shifted screen-left relative to the planted feet).
The exercise name is "Left" because the STRETCH is felt along the left
flank — bending right lengthens the left side. Highlight only "Left
Obliques" (the side actually being stretched, not the side doing the
bending).
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
EXERCISE = "left_standing_side_bend"
VIDEO_NAME = "left_standing_side_bend.mp4"

# Front view reads the lateral C-curve of a side bend best.
CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left oblique",)

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(12)),
        "chest": (0, 0, r(10)),
    },
    60: {
        "spine": (0, 0, r(28)),
        "chest": (0, 0, r(22)),
        "head": (0, 0, r(8)),
    },
    90: {
        "spine": (0, 0, r(28)),
        "chest": (0, 0, r(22)),
        "head": (0, 0, r(8)),
    },
    120: {},
}

L.run(globals())
