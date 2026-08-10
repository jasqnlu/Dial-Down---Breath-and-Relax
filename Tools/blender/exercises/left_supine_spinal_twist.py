"""Left Supine Spinal Twist (Windshield Wipers) — muscle-body + skin-head
animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Mirror of right_supine_spinal_twist.py — see that script's docstring for the
full derivation (sign convention confirmed by coordinate probe, arm angle
reduced from a literal 90 T-shape to 45 to avoid the documented abduction-
tearing failure mode). Instructions here: "let both knees fall gently to
the RIGHT... turn your head to look toward your LEFT hand" — signs flipped
from the right-side script accordingly (thigh Z positive = knees fall
right, head Y positive = look left, both confirmed by the coordinate probe
in the right-side script, not re-eyeballed off a mirrored render).
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
EXERCISE = "left_supine_spinal_twist"
VIDEO_NAME = "left_supine_spinal_twist.mp4"

ROLL_DEG = 0  # flat on the back, no side roll

WORKED_KEYWORDS = ("spinal erector", "lower back", "left obliques")

_ARMS_T = {
    "upperarm.L": (0, 0, r(-45)),
    "upperarm.R": (0, 0, r(45)),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, 0, 0), **_ARMS_T},
    30:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, r(12)), "thigh.R": (r(-90), 0, r(12)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(18), 0), **_ARMS_T},
    60:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, r(20)), "thigh.R": (r(-90), 0, r(20)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(35), 0), **_ARMS_T},
    90:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, r(12)), "thigh.R": (r(-90), 0, r(12)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(18), 0), **_ARMS_T},
    120: {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, 0, 0), **_ARMS_T},
}

L.run_supine(globals())
