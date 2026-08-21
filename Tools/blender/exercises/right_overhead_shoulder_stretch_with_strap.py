"""Right Overhead Shoulder Stretch with Strap — muscle-body + skin-head
animation.

Mirror of left_overhead_shoulder_stretch_with_strap.py — see that script's
docstring. Pitch is sagittal and has no side, so the only change is which
arm "leads" (goes a touch deeper): `upperarm.R` at -165, `upperarm.L` at
-150.

Highlight: Right Shoulder + Right Lats.
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
EXERCISE = "right_overhead_shoulder_stretch_with_strap"
VIDEO_NAME = "right_overhead_shoulder_stretch_with_strap.mp4"

CAMERA_AZIMUTH = 270

WORKED_KEYWORDS = ("right shoulder", "right lats")

POSES = {
    0:   {},
    30:  {"upperarm.R": (r(-100), 0, 0), "upperarm.L": (r(-95), 0, 0),
          "forearm.R": (r(-10), 0, 0), "forearm.L": (r(-10), 0, 0)},
    60:  {"upperarm.R": (r(-165), 0, 0), "upperarm.L": (r(-150), 0, 0),
          "forearm.R": (r(-15), 0, 0), "forearm.L": (r(-15), 0, 0)},
    90:  {"upperarm.R": (r(-165), 0, 0), "upperarm.L": (r(-150), 0, 0),
          "forearm.R": (r(-15), 0, 0), "forearm.L": (r(-15), 0, 0)},
    120: {},
}

L.run(globals())
