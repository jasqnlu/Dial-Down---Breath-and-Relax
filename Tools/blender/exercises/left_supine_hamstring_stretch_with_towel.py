"""Left Supine Hamstring Stretch with Towel — muscle-body + skin-head animation.

Batch 12. "Lie on your back, right knee bent foot flat, straighten your
left leg toward the ceiling." Flat supine base (`hips -90`, same as
right_single_leg_supine_knee_to_chest.py), other leg held in the same
bent-knee-foot-flat rest pose that script uses (`thigh -75, shin +90`).
The moving leg goes straight (`shin 0`) and swings to `thigh -90`, the
exact value legs_up_the_wall.py confirmed puts a straight leg fully
vertical from this same flat-supine base — so a single-leg version should
reach the same "leg toward the ceiling" result. Uses the default oblique
supine camera (not FORCE_TOPDOWN): a straight leg rising toward the
ceiling moves mostly toward an overhead camera and would foreshorten to a
point; the angled oblique view keeps it legible. The towel/strap detail
isn't animated (no hand-target IK).

Highlight: Left Hamstrings.
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
EXERCISE = "left_supine_hamstring_stretch_with_towel"
VIDEO_NAME = "left_supine_hamstring_stretch_with_towel.mp4"

ROLL_DEG = 0

WORKED_KEYWORDS = ("left hamstring",)

_RIGHT_REST = {"thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0)}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-82), 0, 0), "shin.L": (r(40), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0)},
    90:  {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-90), 0, 0), "shin.L": (0, 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0)},
}

L.run_supine(globals())
