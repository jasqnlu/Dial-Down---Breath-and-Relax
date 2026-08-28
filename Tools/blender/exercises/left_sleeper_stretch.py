"""Left Sleeper Stretch (Internal Rotation) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Tier B item (rotation-audit backlog): the first exercise to use `upperarm`
local-Y twist (shoulder internal rotation) — previously untried on an arm
bone (only proven on the vertical spine/chest/head bones). Combines two
already-proven conventions that had never been stacked before: the
side-lying base (`apply_supine_base(roll_deg=±90)`, proven 2026-08-09 for
Supine Chest Opener) plus an arm-bone Y-twist (sign probed fresh today, see
below — NOT reused from the standing-arm probe in the same day's session,
because the standing probe's sign does not transfer: composing the supine
pitch + side roll + forward arm flexion changes what world-direction a given
local-Y sign produces. Re-probing per-configuration, not assuming, per the
project's standing rule for twist axes).

Instructions: "Lie on your left side with your left arm out in front, bent 90
degrees at the elbow, palm down. Keeping your upper arm pinned to the mat,
use your right hand to gently press your left forearm down toward the
floor." The pressing hand isn't modeled (no per-finger articulation, and it's
incidental to the shoulder motion being demonstrated) — the animation shows
the working shoulder's internal rotation itself.

Numeric probe (2026-08-10, throwaway, same setup as here — supine base,
roll_deg=+90, upperarm.L pitched to -90 [out in front], forearm.L pitched to
-90 [elbow bent 90]): swept upperarm.L local-Y from -60 to +60 and logged the
forearm's tail world Z. NEGATIVE local-Y lowered the hand (world Z dropped
from -0.23 at rest to -0.537 at -60deg); POSITIVE raised it. Since "toward
the floor" is the working direction here, this exercise uses NEGATIVE
local-Y on `upperarm.L`. (Mirror-checked against the right-side probe in the
same session: `upperarm.R` needs POSITIVE local-Y for the same downward
motion — confirms this isn't a simple sign-flip-by-side pattern one could
have assumed without probing both.)

ROLL_DEG = +90 puts the RIGHT side up (lying on the LEFT side), per
`apply_supine_base`'s docstring.
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
EXERCISE = "left_sleeper_stretch"
VIDEO_NAME = "left_sleeper_stretch.mp4"

ROLL_DEG = 90  # right side up — lying on the left side
CAMERA_AZIMUTH = 128  # perpendicular to the twist's actual X/Z travel
# direction (probed: forearm.L tail moves roughly (-0.26, 0, -0.34) in X/Z
# from rest to peak) — an ortho camera can't show motion along its own
# view axis at all, and azimuth 45 turned out to point almost straight down
# that motion vector, so rest/peak looked nearly identical despite a real
# ~0.4 unit hand displacement. 128 (solved so the camera's forward direction
# is perpendicular to that displacement) puts the swing in-plane instead.

WORKED_KEYWORDS = ("left shoulder",)

# Default 1.15 clips the reaching hand at this azimuth — this pose's
# silhouette is wider (both arms extended) than the default margin assumes.
ORTHO_SCALE_MULT = 1.55

_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
    # top arm rests forward, out of the way — same "inactive arm" convention
    # as the supine chest-opener scripts use for the bottom arm.
    "upperarm.R": (r(-90), 0, 0),
}

POSES = {
    0:   {**_BASE, "upperarm.L": (r(-90), 0, 0),      "forearm.L": (r(-90), 0, 0)},
    30:  {**_BASE, "upperarm.L": (r(-90), r(-40), 0), "forearm.L": (r(-90), 0, 0)},
    60:  {**_BASE, "upperarm.L": (r(-90), r(-75), 0), "forearm.L": (r(-90), 0, 0)},
    90:  {**_BASE, "upperarm.L": (r(-90), r(-75), 0), "forearm.L": (r(-90), 0, 0)},
    120: {**_BASE, "upperarm.L": (r(-90), 0, 0),      "forearm.L": (r(-90), 0, 0)},
}

L.run_supine_side(globals())
