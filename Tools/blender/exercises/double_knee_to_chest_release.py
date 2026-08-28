"""Double Knee-to-Chest Release — muscle-body + skin-head animation.

Seventh batch, exercise #1. Symmetric version of
left/right_single_leg_supine_knee_to_chest.py — both thighs draw toward the
chest together instead of one. Deliberately did NOT reuse that script's -100
peak thigh angle: -100 was only re-tested and proven for an ASYMMETRIC
single-leg fold (one thigh deep, the other at the shallow -75 rest). Loading
BOTH thighs to the same depth at once is the SYMMETRIC case the rotation
audit already found tears the hip crease at -90 even with the wider
ROLL_DEG=0 blend (see "Getting closer to a real 90-degree bent knee").
Picked -85 as a middle ground — deeper than the proven-safe symmetric -75,
shallower than the confirmed-bad -90 — and rendered to confirm no crease
reopened before shipping (see the script's own render log/PNGs).

FORCE_TOPDOWN (see _lib.py's run_supine docstring) for the same reason as
the single-leg pair: this is a hip-flexion lift, which foreshortens away
under the family's usual oblique camera but reads clearly from overhead.

Highlight: Lower Back + both Glutes groups, matching the exercise's target
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
EXERCISE = "double_knee_to_chest_release"
VIDEO_NAME = "double_knee_to_chest_release.mp4"

ROLL_DEG = 0
FORCE_TOPDOWN = True

WORKED_KEYWORDS = ("lower back", "left glutes", "right glutes")

POSES = {
    0:   {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, 0), "thigh.R": (r(-80), 0, 0),
          "shin.L": (r(100), 0, 0), "shin.R": (r(100), 0, 0)},
    60:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-85), 0, 0), "thigh.R": (r(-85), 0, 0),
          "shin.L": (r(115), 0, 0), "shin.R": (r(115), 0, 0)},
    90:  {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-80), 0, 0), "thigh.R": (r(-80), 0, 0),
          "shin.L": (r(100), 0, 0), "shin.R": (r(100), 0, 0)},
    120: {"hips": (r(-90), 0, 0),
          "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
          "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
