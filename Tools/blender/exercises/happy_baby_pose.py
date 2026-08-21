"""Happy Baby Pose — muscle-body + skin-head animation.

Batch 13. "Lie on your back, draw both knees toward your chest, open your
knees toward your armpits, grab your feet." Same flat-supine double-knee
fold as double_knee_to_chest_release.py (`hips -90`, symmetric `thigh -85 /
shin +115` at peak — reusing that script's already-proven symmetric ceiling
rather than the single-leg -100 ceiling, since both legs move here), with
both thighs additionally abducted outward (local-Z) to open the knees
toward the armpits. FORCE_TOPDOWN camera, same as the knee-to-chest family
— an overhead view reads a knee-opening motion clearly. The
hands-grabbing-feet detail isn't animated (no hand-target IK).

Highlight: Lower Back + both Adductors, matching the exercise's tags.
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
EXERCISE = "happy_baby_pose"
VIDEO_NAME = "happy_baby_pose.mp4"

ROLL_DEG = 0
FORCE_TOPDOWN = True

WORKED_KEYWORDS = ("lower back", "adductor")

POSES = {
    0:   {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, r(-15)), "thigh.R": (r(-80), 0, r(15)),
          "shin.L": (r(100), 0, 0), "shin.R": (r(100), 0, 0)},
    60:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-85), 0, r(-30)), "thigh.R": (r(-85), 0, r(30)),
          "shin.L": (r(115), 0, 0), "shin.R": (r(115), 0, 0)},
    90:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-85), 0, r(-30)), "thigh.R": (r(-85), 0, r(30)),
          "shin.L": (r(115), 0, 0), "shin.R": (r(115), 0, 0)},
    120: {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
