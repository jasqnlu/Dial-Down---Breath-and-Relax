"""Standing Chest Expansion Stretch — muscle-body + skin-head animation.

Fifth batch, exercise #5. Geometrically close to
clasped_hands_behind_back_muscleonly.py's solved behind-the-back pose (same
arm-bone axis signs: upperarm.{L,R} +X/+-Z = shoulder extension + adduction
toward midline; forearm.{L,R} -X = elbow flexion), but this instruction
explicitly says "STRAIGHTEN your arms" and clasp at the LOWER back (not the
mid-back grip clasped-hands uses) — so forearm flexion drops to near-zero
(straight arms) while shoulder extension goes a bit deeper to reach the
lower back and "lift the clasped hands away from the body."

Highlight: WORKED_KEYWORDS = ("chest",) — the muscle group being stretched,
independent of which bone drives the arm motion (same pattern as
reverse_prayer_stretch.py, which highlights forearm/shoulder rather than the
chest/arm bones the pose actually rotates).
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
EXERCISE = "standing_chest_expansion_stretch"
VIDEO_NAME = "standing_chest_expansion_stretch.mp4"

# Same behind-the-back viewing angle as clasped_hands_behind_back.
CAMERA_AZIMUTH = 38

WORKED_KEYWORDS = ("chest",)

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(16), 0, r(7)),
        "upperarm.R": (r(16), 0, r(-7)),
        "forearm.L":  (r(-6), 0, r(4)),
        "forearm.R":  (r(-6), 0, r(-4)),
        "chest":      (r(-4), 0, 0),
    },
    60: {
        "upperarm.L": (r(26), 0, r(11)),
        "upperarm.R": (r(26), 0, r(-11)),
        "forearm.L":  (r(-10), 0, r(6)),
        "forearm.R":  (r(-10), 0, r(-6)),
        "chest":      (r(-8), 0, 0),
    },
    90: {
        "upperarm.L": (r(26), 0, r(11)),
        "upperarm.R": (r(26), 0, r(-11)),
        "forearm.L":  (r(-10), 0, r(6)),
        "forearm.R":  (r(-10), 0, r(-6)),
        "chest":      (r(-8), 0, 0),
    },
    120: {},
}

L.run(globals())
