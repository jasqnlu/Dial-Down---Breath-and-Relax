"""Progressive Relaxation Breath — muscle-body + skin-head animation.

Breathing batch (2026-08-27). Shares the `box_breathing` composition (the
probed base for this batch, see that script's docstring for the full
rationale): seated-chair fold, `chest` bone pulses isotropically via
`SCALE_POSES` (1.0 -> 1.13 -> 1.0), spine/head ease back slightly at peak to
reinforce the inhale read. All 46 breathing exercises share one pose since
what differs between them (inhale/hold/exhale counts, nostril-specific
technique, etc.) is a session-player pacing/instruction concern, not an
animation one — matching this batch's design decision to probe once and
fan out rather than build 46 unique poses. Flagged
`animationIsApproximate` in SeedData: a real diaphragm/ribcage isn't
modeled on this rig, this is a stylized breathing cue.
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
EXERCISE = "progressive_relaxation_breath"
VIDEO_NAME = "progressive_relaxation_breath.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("chest",)

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    60:  {**_LEGS, "spine": (r(-9), 0, 0), "head": (r(-6), 0, 0)},
    120: {**_LEGS},
}

SCALE_POSES = {
    0:   {"chest": (1.0, 1.0, 1.0)},
    60:  {"chest": (1.13, 1.13, 1.13)},
    120: {"chest": (1.0, 1.0, 1.0)},
}

L.run_seated(globals())
