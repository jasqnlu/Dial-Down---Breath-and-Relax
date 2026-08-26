"""Towel Scrunch (Toe Flexor Stretch) — muscle-body + skin-head animation.

20-exercise thin-coverage batch, foot family. "Sit in a chair with a towel
under your feet, scrunch the towel toward you with your toes." No
independent toe joint on this rig — the standard seated-in-chair leg pose
(thigh -90 / shin 90, the same convention seated_neck_rolls/seated_neck_
rotation use for "sitting in a chair" as opposed to the floor-sitting family)
held static, since the actual scrunching motion has no rig geometry to show.

Highlight: both Foot. Flagged `animationIsApproximate`.
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
EXERCISE = "towel_scrunch_toe_flexor_stretch"
VIDEO_NAME = "towel_scrunch_toe_flexor_stretch.mp4"

CAMERA_AZIMUTH = 20
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left foot", "right foot")

_SEATED = {
    "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   dict(_SEATED),
    30:  dict(_SEATED),
    60:  dict(_SEATED),
    90:  dict(_SEATED),
    120: dict(_SEATED),
}

L.run_seated(globals())
