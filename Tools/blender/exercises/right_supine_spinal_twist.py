"""Right Supine Spinal Twist (Windshield Wipers) — muscle-body + skin-head
animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Flat-on-the-back supine base (ROLL_DEG=0 — see ANIMATION_HANDOFF.md's
"Supine pose probe" section), no roll needed for this one. Instructions:
"Lie on your back... let both knees fall gently to the LEFT... turn your
head to look toward your RIGHT hand."

Motion: `thigh.{L,R}` local-Z swings the knees as a unit (kept small, 10deg —
25deg tore geometry at the hip crease in an earlier probe; 10-15deg reads
visibly without tearing). Sign confirmed by a numeric probe, not assumed:
`thigh` local-Z POSITIVE swings the knees toward the subject's own RIGHT
(shin.L world-x went from +0.105 to -0.024, shin.R from -0.105 to -0.234 —
both toward -X, and world +X is established as the subject's left elsewhere
in this doc, so -X = right). This exercise wants the LEFT direction, so
NEGATIVE. `head` local-Y reuses the already-proven twist convention
(+Y = subject's own left, -Y = own right) — that convention is defined
relative to the subject's own body, so it holds regardless of the supine
pitch. "Look toward RIGHT hand" = head local-Y negative.

Tried first: counter-rotating `spine` against a `hips` twist to keep the
shoulders visually still while only the hips/legs move. That does NOT
cancel (probed numerically — spine/chest/head tails moved substantially even
with the opposite sign on spine). This script sidesteps the problem
entirely by never touching `hips`/`spine` beyond the constant base pitch —
only the thigh bones move, so the torso is untouched by construction, not
by a cancellation trick.
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
EXERCISE = "right_supine_spinal_twist"
VIDEO_NAME = "right_supine_spinal_twist.mp4"

ROLL_DEG = 0  # flat on the back, no side roll

WORKED_KEYWORDS = ("spinal erector", "lower back", "right obliques")

_ARMS_T = {
    "upperarm.L": (0, 0, r(-45)),
    "upperarm.R": (0, 0, r(45)),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, 0, 0), **_ARMS_T},
    30:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, r(-12)), "thigh.R": (r(-90), 0, r(-12)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(-18), 0), **_ARMS_T},
    60:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, r(-20)), "thigh.R": (r(-90), 0, r(-20)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(-35), 0), **_ARMS_T},
    90:  {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, r(-12)), "thigh.R": (r(-90), 0, r(-12)),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, r(-18), 0), **_ARMS_T},
    120: {"hips": (r(-90), 0, 0), "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0), "head": (0, 0, 0), **_ARMS_T},
}

L.run_supine(globals())
