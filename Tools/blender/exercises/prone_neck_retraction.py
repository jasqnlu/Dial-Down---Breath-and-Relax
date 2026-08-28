"""Prone Neck Retraction — muscle-body + skin-head animation.

Batch 15. "Lie face-down, forehead on your hands, glide your chin
straight back without lifting your head, repeat slowly." First exercise
to actually use the PRONE half of the supine-probe finding documented in
ANIMATION_HANDOFF.md ("Supine pose probe" section): `hips` local-X = +90
(the mirror of the proven -90 supine base) tips the whole rig face-down
instead of face-up. Every prior prone-sounding exercise (Cobra, Sphinx)
used a standing-arch fallback instead of this convention; this is the
first to use it directly, since here the body genuinely stays flat and
only the head moves — no press-up to complicate it.

The chin-tuck motion reuses chin_tuck_forward_head_reset.py's proven head
local-X axis (a small oscillating glide back and forth, not a single hold,
matching "repeat the glide-and-release rhythm slowly"). Camera: the
oblique supine camera (not top-down) — a face-down head nodding barely
moves in a plane a straight-overhead camera reads well, and the oblique
angle is already proven to keep supine-family motion legible.

Highlight: both Front Neck + Back Neck, matching the exercise's tags.
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
EXERCISE = "prone_neck_retraction"
VIDEO_NAME = "prone_neck_retraction.mp4"

ROLL_DEG = 0
FORCE_TOPDOWN = False

WORKED_KEYWORDS = ("front neck", "back neck")

POSES = {
    0:   {"hips": (r(90), 0, 0)},
    30:  {"hips": (r(90), 0, 0), "head": (r(8), 0, 0)},
    60:  {"hips": (r(90), 0, 0), "head": (r(15), 0, 0)},
    90:  {"hips": (r(90), 0, 0), "head": (r(8), 0, 0)},
    120: {"hips": (r(90), 0, 0)},
}

L.run_supine(globals())
