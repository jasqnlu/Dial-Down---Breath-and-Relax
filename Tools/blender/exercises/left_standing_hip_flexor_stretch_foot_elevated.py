"""Left Standing Hip-Flexor Stretch (Foot Elevated) — muscle-body + skin-head animation.

60-exercise batch. Same single-leg standing shin fold as left_standing_quad_stretch.py (foot rests on a step behind, knee bent) plus a small forward `spine`/`chest` pelvis-tuck lean, matching this exercise's own extra instruction ("gently tuck your pelvis, sinking your hips slightly forward") that the quad-stretch version doesn't have. Highlights Left Hip Flexors instead of Quadriceps since that's the muscle this exercise's own name and instructions call out.

Highlight: Left Hip Flexors.
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
EXERCISE = "left_standing_hip_flexor_stretch_foot_elevated"
VIDEO_NAME = "left_standing_hip_flexor_stretch_foot_elevated.mp4"

WORKED_KEYWORDS = ("left hip",)

CAMERA_AZIMUTH = 90

POSES = {
    0:   {},
    30:  {"shin.L": (r(-40), 0, 0), "spine": (r(4), 0, 0)},
    60:  {"shin.L": (r(-90), 0, 0), "spine": (r(8), 0, 0), "chest": (r(5), 0, 0)},
    90:  {"shin.L": (r(-90), 0, 0), "spine": (r(8), 0, 0), "chest": (r(5), 0, 0)},
    120: {},
}

L.run(globals())
