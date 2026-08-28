"""Standing Adductor Stretch with Chair Support (Right) — muscle-body + skin-head animation.

60-exercise batch. Standing, working leg abducted out to the side (`thigh` local-Z) as if raised onto a chair seat -- an extension of standing_adductor_rock_side_to_side.py's proven small-angle standing abduction, kept to a still-conservative 25deg (up from that script's 15deg) since large standing abduction is documented tearing territory and this is a HELD stretch (bigger sustained angle) rather than a brief rock.

Highlight: Right Adductors.
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
EXERCISE = "standing_adductor_stretch_with_chair_support_right"
VIDEO_NAME = "standing_adductor_stretch_with_chair_support_right.mp4"

WORKED_KEYWORDS = ("right adductor",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    30:  {"thigh.R": (0, 0, r(12))},
    60:  {"thigh.R": (0, 0, r(25))},
    90:  {"thigh.R": (0, 0, r(25))},
    120: {},
}

L.run(globals())
