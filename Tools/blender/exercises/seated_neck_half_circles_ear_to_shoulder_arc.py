"""Seated Neck Half-Circles (Ear-to-Shoulder Arc) — muscle-body + skin-head
animation.

20-exercise thin-coverage batch. "Drop your chin toward your chest, arc your
head so your right ear moves toward your right shoulder, continue the arc
back through center to bring your left ear toward your left shoulder, keep
the motion in the front half only." Same shape as seated_neck_rolls.py — the
proven head local-X (pitch) + local-Z (side bend) combination tracing a
front-hemisphere arc, seated (apply_seated_base/run_seated) — this exercise
IS that same front-half-circle motion under a more literal name, so the
keyframe path is reused directly rather than re-derived.

Highlight: Neck stand-ins Front Neck + Back Neck, matching the exercise's
tags (the broader "Neck" tag has no separate atlas object).
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
EXERCISE = "seated_neck_half_circles_ear_to_shoulder_arc"
VIDEO_NAME = "seated_neck_half_circles_ear_to_shoulder_arc.mp4"

CAMERA_AZIMUTH = 20
PEAK_FRAME = 45

WORKED_KEYWORDS = ("back neck", "front neck")

_SEATED = {
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
}

POSES = {
    0: dict(_SEATED),
    15: {**_SEATED, "head": (0, 0, r(22))},
    30: {**_SEATED, "head": (r(18), 0, r(15))},
    45: {**_SEATED, "head": (r(35), 0, 0)},
    60: {**_SEATED, "head": (r(18), 0, r(-15))},
    75: {**_SEATED, "head": (0, 0, r(-22))},
    90: {**_SEATED, "head": (r(18), 0, r(-15))},
    105: {**_SEATED, "head": (r(35), 0, 0)},
    120: dict(_SEATED),
}

L.run_seated(globals())
