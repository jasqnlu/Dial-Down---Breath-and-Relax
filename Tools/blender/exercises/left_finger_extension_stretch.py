"""Left Finger Extension Stretch — muscle-body + skin-head animation.

New batch (2026-08-27). "Hold left hand out, palm away, use right hand to
pull each finger back." No finger articulation on this rig (rigid mitt,
see rigid_weight() in _lib.py) — same honest-limit approximation as
thumb_extension_stretch_left.py: working arm extended forward with the
assisting arm reaching across, forearm oscillating as the only available
proxy motion. Flagged `animationIsApproximate`.

Highlight: Left Forearm (Hand-only target tags can't highlight the mitt itself).
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
EXERCISE = "left_finger_extension_stretch"
VIDEO_NAME = "left_finger_extension_stretch.mp4"

CAMERA_AZIMUTH = -20
WORKED_KEYWORDS = (['left forearm'])

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-60), 0, r(10)), "forearm.L": (0, 0, r(5)),
          "upperarm.R": (r(-55), 0, r(-15)), "forearm.R": (r(15), 0, 0)},
    60:  {"upperarm.L": (r(-60), 0, r(10)), "forearm.L": (r(-15), 0, r(5)),
          "upperarm.R": (r(-55), 0, r(-15)), "forearm.R": (r(15), 0, 0)},
    90:  {"upperarm.L": (r(-60), 0, r(10)), "forearm.L": (r(-15), 0, r(5)),
          "upperarm.R": (r(-55), 0, r(-15)), "forearm.R": (r(15), 0, 0)},
    120: {},
}

L.run(globals())
