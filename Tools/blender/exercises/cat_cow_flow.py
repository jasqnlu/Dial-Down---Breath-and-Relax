"""Cat-Cow Flow — muscle-body + skin-head animation.

Batch 13 (session push toward 130 exercises). First quadruped exercise
that's a pure oscillation rather than a held stretch — reuses the
hands-and-knees base pose (`spine`/`thigh`/`shin`/planted-arm angles) from
right_thread_the_needle.py verbatim, animating only `spine`'s forward-pitch
angle between two values: LESS flexion (spine closer to horizontal, chest
lifted = Cow) and MORE flexion (spine rounds up = Cat), with `head`
counter-animating (tips up for Cow, tucks down for Cat) the same way the
already-shipped neck-extension/chin-tuck pair does.

Highlight: Spinal Erectors + both Abs, matching the exercise's tags.
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
EXERCISE = "cat_cow_flow"
VIDEO_NAME = "cat_cow_flow.mp4"

CAMERA_AZIMUTH = 30

WORKED_KEYWORDS = ("spinal erector", "abs")

_LEGS_ARMS = {
    "thigh.L": (r(5), 0, 0), "thigh.R": (r(5), 0, 0),
    "shin.L": (r(100), 0, 0), "shin.R": (r(100), 0, 0),
    "upperarm.L": (r(-68), 0, 0), "forearm.L": (r(25), 0, 0),
    "upperarm.R": (r(-68), 0, 0), "forearm.R": (r(25), 0, 0),
}

POSES = {
    # Cow: less spine flexion, head lifts.
    0:   {"spine": (r(85), 0, 0), "chest": (r(-8), 0, 0), "head": (r(-15), 0, 0), **_LEGS_ARMS},
    30:  {"spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": (r(-10), 0, 0), **_LEGS_ARMS},
    # Cat: more spine flexion, head tucks.
    60:  {"spine": (r(110), 0, 0), "chest": (r(5), 0, 0), "head": (r(15), 0, 0), **_LEGS_ARMS},
    90:  {"spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": (r(-10), 0, 0), **_LEGS_ARMS},
    120: {"spine": (r(85), 0, 0), "chest": (r(-8), 0, 0), "head": (r(-15), 0, 0), **_LEGS_ARMS},
}

L.run_quadruped(globals())
