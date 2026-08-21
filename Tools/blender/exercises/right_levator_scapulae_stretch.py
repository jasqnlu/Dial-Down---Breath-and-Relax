"""Right Levator Scapulae Stretch — muscle-body + skin-head animation.

Mirror of left_levator_scapulae_stretch.py — see that script's docstring for
the full derivation. Instructions here: "turn your head about 45 degrees to
the LEFT... look down toward your left armpit" — turning left = +Y (see the
left script's docstring for the numeric probe that pins this sign; +Y = the
subject's own left, the same convention the chest/spine twist family uses).
Tuck (+X) unchanged since it's not a sided motion.

Highlight: Back Neck + Right Trapezius (the side being stretched).
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
EXERCISE = "right_levator_scapulae_stretch"
VIDEO_NAME = "right_levator_scapulae_stretch.mp4"

CAMERA_AZIMUTH = 315

WORKED_KEYWORDS = ("back neck", "right trapezius")

POSES = {
    0: {},
    30: {"head": (r(8), r(-25), 0)},
    60: {"head": (r(14), r(-45), 0)},
    90: {"head": (r(14), r(-45), 0)},
    120: {},
}

L.run(globals())
