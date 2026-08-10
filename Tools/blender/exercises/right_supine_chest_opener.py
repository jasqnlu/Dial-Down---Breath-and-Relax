"""Right Supine Chest Opener (Open Book) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

First use of the supine base pose (see ANIMATION_HANDOFF.md's "Supine pose
probe" section, 2026-08-09) — `hips` local-X = -90 tips the whole rig flat,
face-up, and this exercise additionally rolls it onto its side via
`apply_supine_base`'s ROLL_DEG (an object-level rotation, proven to roll the
body around its own length axis without tearing, unlike stacking a second
hips pose-bone rotation which just re-spins the flat body instead).

Instructions: "Lie on your LEFT side... slowly open your RIGHT arm up and
over toward the floor behind you... let your upper back and right chest
rotate open toward the ceiling." ROLL_DEG = +90 puts the RIGHT side up
(verified by bone-tail Z comparison against the roll-probe render, not
assumed) — the correct side for the RIGHT arm to be the one opening upward.
The arm sweep uses the proven flexion axis (local-X on upperarm, "-X =
forward") from a forward starting position (~shoulder height) through
overhead to behind — a wide arc, but still pure flexion, the axis already
established as tear-resistant up to -150; watch the render for tearing
past that since this goes further.
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
EXERCISE = "right_supine_chest_opener"
VIDEO_NAME = "right_supine_chest_opener.mp4"

ROLL_DEG = 90  # right side up — see docstring

WORKED_KEYWORDS = ("right chest", "spinal erector")

# Constant supine base every frame; hips local-X = -90 tips flat (see
# apply_supine_base). Legs stay bent/stacked (the instructions say "knees
# bent toward your chest, knees stacked") — reuse the seated hip-flexion
# convention on both thighs/shins since both legs stay together throughout,
# no independent leg motion needed for this exercise.
_BASE = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-90), 0, 0),
    "thigh.R": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
    "shin.R": (r(90), 0, 0),
    "upperarm.L": (r(-90), 0, 0),  # bottom arm stays forward, out of the way
}

POSES = {
    0:   {**_BASE, "upperarm.R": (r(-90), 0, 0), "chest": (0, 0, 0)},
    30:  {**_BASE, "upperarm.R": (r(-150), 0, 0), "chest": (0, r(10), 0)},
    60:  {**_BASE, "upperarm.R": (r(-215), 0, 0), "chest": (0, r(20), 0)},
    90:  {**_BASE, "upperarm.R": (r(-150), 0, 0), "chest": (0, r(10), 0)},
    120: {**_BASE, "upperarm.R": (r(-90), 0, 0), "chest": (0, 0, 0)},
}

L.run_supine(globals())
