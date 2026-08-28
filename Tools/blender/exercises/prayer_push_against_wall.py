"""Prayer Push Against Wall — muscle-body + skin-head animation.

Eighth batch, exercise #2. Related to prayer_stretch_palms_together_lower.py
but a different hand shape: that exercise's palms touch EACH OTHER at the
midline; this one presses both palms flat against a wall in front, roughly
shoulder-width apart, fingers pointing down (a wrist articulation this rig
can't represent — no wrist bone — so the visible difference from the
midline-palms shape is the hands staying apart at forward reach instead of
converging). Arms stay nearly straight (`forearm` only lightly flexed,
unlike the prayer stretch's deep elbow fold) since the reach is forward to
a wall, not up to the chest. "Lower your body slightly" is approximated as
a small added forward chest/spine lean (the rig has no knee-bend-to-sink
motion isolated from the hip-fold conventions used elsewhere) — small
enough to read as a gentle increase in stretch, not a squat.

Highlight: WORKED_KEYWORDS = ("forearm",) — same target as the prayer
stretch.
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
EXERCISE = "prayer_push_against_wall"
VIDEO_NAME = "prayer_push_against_wall.mp4"

CAMERA_AZIMUTH = 70

WORKED_KEYWORDS = ("forearm",)

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(-30), 0, r(6)), "upperarm.R": (r(-30), 0, r(-6)),
        "forearm.L": (r(-12), 0, 0), "forearm.R": (r(-12), 0, 0),
    },
    60: {
        "upperarm.L": (r(-40), 0, r(8)), "upperarm.R": (r(-40), 0, r(-8)),
        "forearm.L": (r(-16), 0, 0), "forearm.R": (r(-16), 0, 0),
        "spine": (r(6), 0, 0),
    },
    90: {
        "upperarm.L": (r(-40), 0, r(8)), "upperarm.R": (r(-40), 0, r(-8)),
        "forearm.L": (r(-16), 0, 0), "forearm.R": (r(-16), 0, 0),
        "spine": (r(6), 0, 0),
    },
    120: {},
}

L.run(globals())
