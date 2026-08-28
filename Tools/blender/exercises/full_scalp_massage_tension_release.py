"""Full Scalp Massage (Tension Release) — muscle-body + skin-head animation.

20-exercise thin-coverage batch. "Place your fingertips on your scalp,
spread wide like a claw, move in small circles, work from your hairline
back toward the crown." Both hands reach to the TOP of the head — closer to
the "opposite-side hand to top of head" target family
(left/right_levator_scapulae_stretch.py) than the temple-massage exercise's
above-the-ear target, mirrored onto both arms simultaneously since this is
bilateral. Same small head Z-oscillation as circular_temple_self_massage.py
stands in for the circular massage motion.

Highlight: Head — unlike Temple/Jaw/Eye/Forehead, "Head" IS one of the 41
mappable muscle groups (see the muscle-group -> bone table), so this is the
one face-adjacent exercise in this batch that gets a real highlight.
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
EXERCISE = "full_scalp_massage_tension_release"
VIDEO_NAME = "full_scalp_massage_tension_release.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("head",)

# Own-side hand reaching to the top of the head — mirrored onto both arms.
_ARMS_UP = {
    "upperarm.L": (r(-130), 0, r(10)), "forearm.L": (r(-100), 0, r(-25)),
    "upperarm.R": (r(-130), 0, r(-10)), "forearm.R": (r(-100), 0, r(25)),
}

POSES = {
    0:   {},
    30:  {**_ARMS_UP, "head": (0, 0, r(-3))},
    60:  {**_ARMS_UP, "head": (0, 0, r(3))},
    90:  {**_ARMS_UP, "head": (0, 0, r(-3))},
    120: {},
}

L.run(globals())
