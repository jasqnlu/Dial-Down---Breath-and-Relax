"""Left Overhead Shoulder Stretch with Strap — muscle-body + skin-head
animation.

Ninth batch, exercise #3. Both arms reach straight overhead then tip
backward together ("lower the strap behind your head and toward your upper
back, arms straight") — pure `upperarm` local-X near the overhead ceiling
already proven safe (-150 to -160 range, used by the overhead-reach and
overhead-triceps families), with `forearm` left nearly straight (small
constant flex) instead of the overhead-triceps family's deep fold, since a
strap keeps the arms straight here. "Lead slightly with the left arm" is a
small asymmetry: `upperarm.L` goes a touch deeper than `upperarm.R`
(-165 vs -150) rather than a different axis.

Highlight: Left Shoulder + Left Lats, matching the exercise's target tags.
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
EXERCISE = "left_overhead_shoulder_stretch_with_strap"
VIDEO_NAME = "left_overhead_shoulder_stretch_with_strap.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left shoulder", "left lats")

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-100), 0, 0), "upperarm.R": (r(-95), 0, 0),
          "forearm.L": (r(-10), 0, 0), "forearm.R": (r(-10), 0, 0)},
    60:  {"upperarm.L": (r(-165), 0, 0), "upperarm.R": (r(-150), 0, 0),
          "forearm.L": (r(-15), 0, 0), "forearm.R": (r(-15), 0, 0)},
    90:  {"upperarm.L": (r(-165), 0, 0), "upperarm.R": (r(-150), 0, 0),
          "forearm.L": (r(-15), 0, 0), "forearm.R": (r(-15), 0, 0)},
    120: {},
}

L.run(globals())
