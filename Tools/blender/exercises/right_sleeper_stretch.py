"""Right Sleeper Stretch (Internal Rotation) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Mirror of left_sleeper_stretch.py — see that script's docstring for the full
derivation. Numeric probe (2026-08-10, roll_deg=-90, upperarm.R pitched to
-90, forearm.R pitched to -90): swept upperarm.R local-Y and logged the
forearm's tail world Z. POSITIVE local-Y lowered the hand toward the floor
here (opposite sign from the left side's probe — not a simple mirror
assumption, both sides were independently probed).

ROLL_DEG = -90 puts the LEFT side up (lying on the RIGHT side).
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
EXERCISE = "right_sleeper_stretch"
VIDEO_NAME = "right_sleeper_stretch.mp4"

ROLL_DEG = -90  # left side up — lying on the right side
# Mirror of left_sleeper_stretch.py's azimuth fix: run_supine_side's Y-orbit
# camera needs to sit roughly perpendicular to the twist's actual X/Z travel
# direction, or an ortho camera shows almost no motion (see that script's
# docstring for the full derivation — first pass here inherited the naive
# 270 mirror of the old top-down convention and had the same "peak looks
# like rest" problem). 232 was solved the same way (perpendicular to the
# probed hand-travel direction) and confirmed by render.
CAMERA_AZIMUTH = 232

WORKED_KEYWORDS = ("right shoulder",)

# See left_sleeper_stretch.py — default 1.15 clips the reaching hand here too.
ORTHO_SCALE_MULT = 1.55

_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
    "upperarm.L": (r(-90), 0, 0),
}

POSES = {
    0:   {**_BASE, "upperarm.R": (r(-90), 0, 0),      "forearm.R": (r(-90), 0, 0)},
    30:  {**_BASE, "upperarm.R": (r(-90), r(40), 0),  "forearm.R": (r(-90), 0, 0)},
    60:  {**_BASE, "upperarm.R": (r(-90), r(75), 0),  "forearm.R": (r(-90), 0, 0)},
    90:  {**_BASE, "upperarm.R": (r(-90), r(75), 0),  "forearm.R": (r(-90), 0, 0)},
    120: {**_BASE, "upperarm.R": (r(-90), 0, 0),      "forearm.R": (r(-90), 0, 0)},
}

L.run_supine_side(globals())
