"""Left Standing Tibialis Stretch (Toe Point) — muscle-body + skin-head animation.

Batch 13. "Slide your foot slightly behind you and point your toes,
pressing the top of the foot toward the floor." First pose on this rig to
use `thigh` HIP EXTENSION (swinging the leg backward) rather than flexion —
every prior standing-leg pose (standing quad stretch, seated poses) only
ever flexed the thigh forward/up. By analogy to the arm's proven
convention ("+X = swing back" for `upperarm`, since both bones hang the
same way per Gotcha #6), hip extension should be POSITIVE local-X — kept
small (18 deg, "slide your foot SLIGHTLY behind") since this is genuinely
untested territory for the thigh bone specifically. The toe-point/ankle
detail can't be shown (no independent ankle joint); the stretch reads
through the leg silhouette + shin highlight.

Highlight: Left Tibialis.
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
EXERCISE = "left_standing_tibialis_stretch_toe_point"
VIDEO_NAME = "left_standing_tibialis_stretch_toe_point.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left tibialis",)

POSES = {
    0:   {},
    30:  {"thigh.L": (r(10), 0, 0)},
    60:  {"thigh.L": (r(18), 0, 0)},
    90:  {"thigh.L": (r(18), 0, 0)},
    120: {},
}

L.run(globals())
