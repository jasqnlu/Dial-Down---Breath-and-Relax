"""Seated Forward Fold — muscle-body + skin-head animation.

Seventh batch, exercise #3. First seated exercise with STRAIGHT legs —
every prior `run_seated` caller (both seated spinal twists) uses the
bent-knee `thigh -90 / shin +90` fold. Here the instructions extend both
legs straight out in front ("sit on the floor with both legs extended"), so
`shin.{L,R}` stays at 0 (straight) instead of +90 (folded) while `thigh`
keeps the same -90 (hip flexed to horizontal, matching a floor-sitting hip
angle).

`apply_seated_base`'s pelvis-drop constant (0.46) was measured against the
BENT-KNEE hover height, not this straight-leg pose — the geometry differs
(a straight leg's foot lands at a different height than a folded one), so
the feet may not sit exactly on the floor here. Accepted as the same class
of approximation the rest of this pipeline already carries (e.g. the
quadruped arm reach, the figure-4 ankle contact) rather than deriving a
second seated-drop constant for one exercise — reviewed the render for a
grossly wrong foot height before shipping, not a floor-contact analysis.

Forward fold: `spine`/`chest` local-X (the proven forward-pitch axis),
smaller magnitude than the standing version
(standing_forward_fold_ragdoll.py) since the hip is already flexed 90 deg
by the seated pose — folding as far again would be an unrealistic double
hinge. Arms reach forward with the torso (small `upperarm` local-X,
UNMIRRORED from the ragdoll script's cancel-the-parent-pitch trick — here
the arms SHOULD swing forward with the fold, reaching toward the feet, not
hang world-vertical).

Highlight: Spinal Erectors + Hamstrings, matching the exercise's target
tags (Lower Back is also tagged but Spinal Erectors covers the same visual
region without over-highlighting).
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
EXERCISE = "seated_forward_fold"
VIDEO_NAME = "seated_forward_fold.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.4

WORKED_KEYWORDS = ("spinal erector", "hamstring")

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0),
    "shin.L": (0, 0, 0), "shin.R": (0, 0, 0),
}

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(15), 0, 0), "chest": (r(10), 0, 0),
          "upperarm.L": (r(-20), 0, 0), "upperarm.R": (r(-20), 0, 0)},
    60:  {**_LEGS, "spine": (r(30), 0, 0), "chest": (r(20), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    90:  {**_LEGS, "spine": (r(30), 0, 0), "chest": (r(20), 0, 0),
          "head": (r(10), 0, 0),
          "upperarm.L": (r(-45), 0, 0), "upperarm.R": (r(-45), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
