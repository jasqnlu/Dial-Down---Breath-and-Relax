"""Standing Broom-Stick Rotation (Torso Twist with Prop) — muscle-body + skin-head animation.

60-exercise batch. Standing `chest`/`spine` local-Y twist alternating both directions in one loop (the confirmed "-Y=right, +Y=left" convention), reusing the seated-spinal-twist family's proven twist magnitude.

Highlight: Left Obliques, Right Obliques.
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
EXERCISE = "standing_broom_stick_rotation_torso_twist_with_prop"
VIDEO_NAME = "standing_broom_stick_rotation_torso_twist_with_prop.mp4"

WORKED_KEYWORDS = ("oblique",)

CAMERA_AZIMUTH = 0

POSES = {
    0:   {},
    30:  {"chest": (0, r(-22), 0), "spine": (0, r(-14), 0)},
    60:  {},
    90:  {"chest": (0, r(22), 0), "spine": (0, r(14), 0)},
    120: {},
}

L.run(globals())
