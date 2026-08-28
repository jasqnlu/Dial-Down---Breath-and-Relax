"""Left Overhead Reach Lat Stretch with Strap — muscle-body + skin-head
animation.

Ninth batch, exercise #5. Bilateral version of left_standing_side_reach.py
— same proven torso side-bend (+Z bends the subject's own right, matching
this LEFT-named stretch's "reach up and over to the right"), but BOTH arms
go overhead (holding a shared strap/towel) instead of just the named side's
arm. `upperarm.R` gets the same overhead flexion as `upperarm.L` — both
inherit the chest's rightward bend as child bones, same as the single-arm
version, so no extra adduction is needed on either side.

Highlight: Left Lats + Left Shoulder, matching the exercise's target tags.
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
EXERCISE = "left_overhead_reach_lat_stretch_with_strap"
VIDEO_NAME = "left_overhead_reach_lat_stretch_with_strap.mp4"

CAMERA_AZIMUTH = 0

WORKED_KEYWORDS = ("left lats", "left shoulder")

POSES = {
    0: {},
    30: {
        "spine": (0, 0, r(12)), "chest": (0, 0, r(10)),
        "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
    },
    60: {
        "spine": (0, 0, r(26)), "chest": (0, 0, r(20)), "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0),
    },
    90: {
        "spine": (0, 0, r(26)), "chest": (0, 0, r(20)), "head": (0, 0, r(6)),
        "upperarm.L": (r(-150), 0, 0), "upperarm.R": (r(-150), 0, 0),
    },
    120: {},
}

L.run(globals())
