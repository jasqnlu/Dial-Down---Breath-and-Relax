"""Left Upper Trapezius Stretch — muscle-body + skin-head animation.

Fifth batch, exercise #3. Pure lateral tilt, the same local-Z side-bend axis
proven by left_scalene_neck_stretch.py — but WITHOUT that script's small
pitch/twist components, since this instruction is a single clean motion
("gently tilt your right ear toward your right shoulder") with no "slightly
upward" or "toward the side" qualifiers to chase. Taken to a bigger Z angle
than the scalene stretch's "slightly" version since nothing else is
competing for range here.

Instruction: "tilt your RIGHT ear toward your RIGHT shoulder" — a LEFT-named
stretch tilting right, same bilateral convention as the scalene/side-bend
family (+Z = tilt toward the subject's own right, per
ANIMATION_HANDOFF.md's confirmed sign).

Highlight: Left Trapezius directly — this exercise names the muscle in its
own title, unlike the scalene stretch which needed Front Neck for the
primary target.
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
EXERCISE = "left_upper_trapezius_stretch"
VIDEO_NAME = "left_upper_trapezius_stretch.mp4"

# Mostly front-on — a pure lateral tilt reads best face-on (same reasoning as
# the scalene stretch's low azimuth).
CAMERA_AZIMUTH = 15

WORKED_KEYWORDS = ("left trapezius",)

POSES = {
    0: {},
    30: {"head": (0, 0, r(18))},
    60: {"head": (0, 0, r(32))},
    90: {"head": (0, 0, r(32))},
    120: {},
}

L.run(globals())
