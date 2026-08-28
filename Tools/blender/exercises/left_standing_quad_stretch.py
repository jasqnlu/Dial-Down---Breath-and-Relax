"""Left Standing Quad Stretch — muscle-body + skin-head animation.

Batch 12. "Stand on your right leg, bend your left knee and grasp your
ankle behind you." First single-leg standing balance pose animated purely
via `shin` local-X, with `thigh` left at rest (vertical, matching a
standing leg) — the standing leg (right) is untouched throughout. Sign
derived by analogy to the forearm ("-X flexes the elbow, folding the hand
in behind") since a vertical-thigh `shin` hangs the same way a resting
`forearm` does (local Y = world -Z) — so -X should fold the shin backward
the same way. Verified by rendering rather than assumed; if the foot swings
forward instead of behind, the sign needs flipping. The grasping hand isn't
animated (no hand-target IK).

Highlight: Left Quadriceps, the muscle named in the exercise itself.
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
EXERCISE = "left_standing_quad_stretch"
VIDEO_NAME = "left_standing_quad_stretch.mp4"

# Side view reads a knee fold behind the body best.
CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left quadricep",)

POSES = {
    0:   {},
    30:  {"shin.L": (r(-60), 0, 0)},
    60:  {"shin.L": (r(-115), 0, 0)},
    90:  {"shin.L": (r(-115), 0, 0)},
    120: {},
}

L.run(globals())
