"""Reverse Prayer Shoulder Mobiliser — muscle-body + skin-head animation.

Eighth batch, exercise #6. Same shape as reverse_prayer_stretch.py ("bring
your arms behind you and try to press your palms together in reverse
prayer... lift your chest") — reuses that script's exact solved pose
verbatim, since the instructions describe the same clasp. Differs only in
which muscle groups get highlighted: this exercise's own target tags are
Shoulder + Chest rather than reverse_prayer_stretch's Forearm + Shoulder,
so the highlight follows this exercise's tags even though the pose is
identical.

Highlight: Shoulder + Chest (both sides).
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
EXERCISE = "reverse_prayer_shoulder_mobiliser"
VIDEO_NAME = "reverse_prayer_shoulder_mobiliser.mp4"

CAMERA_AZIMUTH = 38

WORKED_KEYWORDS = ("shoulder", "chest")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(14), 0, r(6)),
        "upperarm.R": (r(14), 0, r(-6)),
        "forearm.L":  (r(-18), 0, r(11)),
        "forearm.R":  (r(-18), 0, r(-11)),
    },
    60: {
        "upperarm.L": (r(22), 0, r(10)),
        "upperarm.R": (r(22), 0, r(-10)),
        "forearm.L":  (r(-28), 0, r(18)),
        "forearm.R":  (r(-28), 0, r(-18)),
    },
    90: {
        "upperarm.L": (r(22), 0, r(10)),
        "upperarm.R": (r(22), 0, r(-10)),
        "forearm.L":  (r(-28), 0, r(18)),
        "forearm.R":  (r(-28), 0, r(-18)),
    },
    120: {},
}

L.run(globals())
