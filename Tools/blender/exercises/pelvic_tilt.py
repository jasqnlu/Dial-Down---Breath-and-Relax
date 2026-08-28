"""Pelvic Tilt — muscle-body + skin-head animation.

Seventh batch, exercise #2. "Flatten your lower back into the mat by
gently tilting your pelvis... repeat 10-12 times." A genuinely subtle
motion — this is deliberately NOT animated via the `hips` bone (the rig's
unparented root; rotating it moves the ENTIRE figure, torso and legs
included, which would read as a much bigger motion than a real pelvic tilt
and defeats the "keep everything else still" nature of the exercise). Used
a small oscillating `spine` local-X instead (the proven forward-pitch axis,
at a much smaller angle than any other use of it) to read as a subtle
lower-back flattening/release without moving the pelvis or legs at all.
Base leg pose reuses the proven windshield-wiper rest fold ("knees bent,
feet flat on the floor" — the same resting silhouette used everywhere else
in the supine family), held constant across every keyframe.

Uses the default oblique supine camera (no FORCE_TOPDOWN) — unlike the
knee-to-chest exercises, this motion is intentionally almost invisible (a
few degrees of spine curl), and no camera angle will make it dramatic; the
oblique framing at least keeps the "lying down" read honest.

Highlight: Abs + Lower Back, matching the exercise's target tags (Spinal
Erectors/Lower Spine are also tagged but Abs + Lower Back cover both sides
of the motion without over-highlighting).
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
EXERCISE = "pelvic_tilt"
VIDEO_NAME = "pelvic_tilt.mp4"

ROLL_DEG = 0

WORKED_KEYWORDS = ("abs", "lower back")

# Same "repeated motion lands on a neutral keyframe" quirk as
# suboccipital_release_finger_press.py — frame 60 (the default preview
# frame) is neutral here; 30 is tilted, more representative of the exercise.
PEAK_FRAME = 30

_LEGS = {
    "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
    "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_LEGS},
    30:  {"hips": (r(-90), 0, 0), **_LEGS, "spine": (r(8), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_LEGS},
    90:  {"hips": (r(-90), 0, 0), **_LEGS, "spine": (r(8), 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_LEGS},
}

L.run_supine(globals())
