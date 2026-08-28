"""Left Single-Leg Supine Knee-to-Chest — muscle-body + skin-head animation.

Sixth batch, exercise #5. First supine exercise where only ONE leg moves —
every prior supine script (chest opener, spinal twist, figure-4) animates
both legs together or symmetrically. Base "both knees bent, feet flat"
resting position reuses the proven windshield-wiper fold (`thigh` -75,
`shin` +90 — see ANIMATION_HANDOFF.md's "Supine Spinal Twist hip-crease
tear" section for why -75, not -90, is the safe ceiling even with the wider
ROLL_DEG=0 blend `run_supine` already applies). The RIGHT leg stays at that
constant rest fold for the whole clip ("keep your right foot flat"); only
`thigh.L`/`shin.L` animate further, toward the chest.

First attempt kept the working leg's THIGH pinned at the same -75 ceiling
and only animated the shin (heel toward the glute) to avoid touching the
hip-crease tearing history — rendered clean, but from the family's default
oblique supine camera the "knee toward chest" motion was nearly invisible:
the thigh, the segment whose position actually reads as "closer to the
chest," never moved at all. Fixed two ways together, not by re-trying the
same shin-only approach at a different angle:

1. The working `thigh.L` now animates too (-75 rest -> -100 peak), deeper
   than the previously-proven -75 ceiling. That ceiling was established for
   a SYMMETRIC two-leg fold (both thighs loading the same hip-crease seam
   at once, see the "Getting closer to a real 90-degree bent knee" section);
   an single-leg fold loads only one side, so it was re-tested rather than
   assumed unsafe — rendered clean at -100 with the wider ROLL_DEG=0 blend
   `run_supine` already applies, no tear at the crease.
2. `FORCE_TOPDOWN=True` (new `_lib.py` option, see its docstring) swaps in
   the plain overhead camera instead of this family's usual oblique one —
   a hip-flexion lift reads clearly in the top-down footprint (the knee
   visibly travels toward the torso) but foreshortens badly from the
   oblique angle, which was tuned for the WINDSHIELD-WIPER exercises'
   side-to-side sweep instead.

Highlight: Lower Back + Left Glutes, matching the exercise's own target
tags.
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
EXERCISE = "left_single_leg_supine_knee_to_chest"
VIDEO_NAME = "left_single_leg_supine_knee_to_chest.mp4"

ROLL_DEG = 0  # flat on the back
FORCE_TOPDOWN = True  # see _lib.py's run_supine docstring

WORKED_KEYWORDS = ("lower back", "left glutes")

_RIGHT_REST = {"thigh.R": (r(-75), 0, 0), "shin.R": (r(90), 0, 0)}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-88), 0, 0), "shin.L": (r(105), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-100), 0, 0), "shin.L": (r(120), 0, 0)},
    90:  {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-88), 0, 0), "shin.L": (r(105), 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_RIGHT_REST,
          "thigh.L": (r(-75), 0, 0), "shin.L": (r(90), 0, 0)},
}

L.run_supine(globals())
