"""Left Isometric Neck Side Press — muscle-body + skin-head animation.

Batch 15. "Press your head into your resisting hand so your head doesn't
actually move." A genuinely isometric exercise — literally correct would
be zero head motion, but per suboccipital_release_finger_press.py's
precedent (a "press" cue reads better with a small oscillation implying
effort than a frozen frame), animated a small head local-Z side-bend
oscillation (the same axis the upper-trapezius/scalene family already
proved) rather than a true hold. The resisting hand isn't animated (no
hand-target IK).

Highlight: Left Trapezius + Front Neck, matching the exercise's tags.
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
EXERCISE = "left_isometric_neck_side_press"
VIDEO_NAME = "left_isometric_neck_side_press.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left trapezius", "front neck")

POSES = {
    0:   {},
    30:  {"head": (0, 0, r(-4))},
    60:  {"head": (0, 0, r(-7))},
    90:  {"head": (0, 0, r(-4))},
    120: {},
}

L.run(globals())
