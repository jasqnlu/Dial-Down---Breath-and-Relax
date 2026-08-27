"""Standing Wall Angels (Trapezius Mobility Flow) — muscle-body + skin-head animation.

40-exercise thin-coverage batch (session 2026-08-26). Bilateral overhead arm slide, same overhead-flexion axis the reach/lat family uses (upperarm local-X), no adduction (the axis documented to tear) so the rig stays stable.

Highlight: both Trapezius.
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
EXERCISE = "standing_wall_angels_trapezius_mobility_flow"
VIDEO_NAME = "standing_wall_angels_trapezius_mobility_flow.mp4"

CAMERA_AZIMUTH = 0
WORKED_KEYWORDS = ("left trapezius", "right trapezius")

POSES = {
    0: {},
    30: {"upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0),
         "forearm.L": (r(-20), 0, 0), "forearm.R": (r(-20), 0, 0)},
    60: {"upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0),
         "forearm.L": (r(-10), 0, 0), "forearm.R": (r(-10), 0, 0)},
    90: {"upperarm.L": (r(-140), 0, 0), "upperarm.R": (r(-140), 0, 0),
         "forearm.L": (r(-10), 0, 0), "forearm.R": (r(-10), 0, 0)},
    120: {},
}

L.run(globals())
