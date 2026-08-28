"""Shoulder Roll — muscle-body + skin-head animation.

Batch 10. "Lift both shoulders toward your ears, roll them back and down in
a circle, squeezing the shoulder blades together." A true shoulder roll is
a scapular motion; this rig has no scapula/clavicle bone, only the humerus
(`upperarm`) and torso (`chest`/`spine`), so a literal circular scapular
path can't be traced. Approximated in two beats instead of a real circle:
a small bilateral shoulder lift (`upperarm` local-Z, both sides, small
angle — 8deg, well under the abduction-tearing thresholds documented in
ANIMATION_HANDOFF.md) followed by a small `chest` backward extension
(local-X) standing in for "squeeze the shoulder blades together." Flagged
`animationIsApproximate` in SeedData.

Highlight: both Trapezius + both Shoulders, matching the exercise's tags.
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
EXERCISE = "shoulder_roll"
VIDEO_NAME = "shoulder_roll.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("trapezius", "shoulder")

POSES = {
    0:   {},
    30:  {"upperarm.L": (0, 0, r(8)), "upperarm.R": (0, 0, r(-8))},
    60:  {"upperarm.L": (0, 0, r(4)), "upperarm.R": (0, 0, r(-4)),
          "chest": (r(-8), 0, 0)},
    90:  {"upperarm.L": (0, 0, r(4)), "upperarm.R": (0, 0, r(-4)),
          "chest": (r(-8), 0, 0)},
    120: {},
}

L.run(globals())
