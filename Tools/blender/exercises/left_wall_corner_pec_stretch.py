"""Left Wall Corner Pec Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #9. The first script to
use a LARGE arm abduction (local-Z ~85 deg) rather than the small-to-moderate
angles every prior arm pose used — "elbow at shoulder height" requires lifting
the upper arm to horizontal, out to the side.

Axes:
  * upperarm.L local-Z NEGATIVE 85 = abduction. Per Gotcha #6, +Z on the LEFT
    arm adducts toward the midline, so the negative direction swings it away
    from the body and up to horizontal.
  * forearm.L local-X -75 = elbow folded so the forearm rests flat on the
    wall, pointing up from the horizontal upper arm.
  * chest/spine local-Y NEGATIVE = rotate toward the subject's own right,
    i.e. "rotate your chest away from the corner" when the planted forearm is
    the left one. See ANIMATION_HANDOFF.md "Twist direction" — negative is
    right; the doc's pre-2026-08-08 claim of the opposite was wrong.

RISK NOTE: 85 deg of abduction is the largest arm rotation attempted on this
rig. Gotcha #2 warns the arms-down source mesh bleeds weight into the torso,
which is what tore the skin shell in the earliest experiments. The muscle-only
figure plus joint-blend weighting is expected to hold, but this render must be
eyeballed at the shoulder specifically before shipping, not just the log.
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
EXERCISE = "left_wall_corner_pec_stretch"
VIDEO_NAME = "left_wall_corner_pec_stretch.mp4"

# Mostly front-on so the abducted arm reads at full width, angled slightly to
# also catch the chest rotation.
CAMERA_AZIMUTH = 30
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("left chest",)

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(-38), 0, r(-18)),
        "forearm.L": (r(-30), 0, 0),
    },
    60: {
        "upperarm.L": (r(-62), 0, r(-30)),
        "forearm.L": (r(-55), 0, 0),
        "chest": (0, r(-18), 0),
        "spine": (0, r(-8), 0),
    },
    90: {
        "upperarm.L": (r(-62), 0, r(-30)),
        "forearm.L": (r(-55), 0, 0),
        "chest": (0, r(-18), 0),
        "spine": (0, r(-8), 0),
    },
    120: {},
}

L.run(globals())
