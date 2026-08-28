"""Sphinx Pose — muscle-body + skin-head animation.

Eighth batch, exercise #1. Same fallback this rig already uses for any
face-down floor pose: cobra_stretch_prone_press_up.py's docstring explains
"the rig has no floor/prone-lying representation, so this is approximated
as a standing-figure backward arch." (A face-down prone base IS possible in
principle — `apply_supine_base`'s docstring documents `hips` local-X=+90 as
prone — but that function hardcodes -90/face-up and exposing the mirror
would be new plumbing; reusing the already-proven standing-arch fallback
was faster and keeps this family visually consistent with cobra.) Shallower
than cobra's press-up (peak spine/chest/head -8/-22/-15) since Sphinx is
propped on the forearms, a gentler backbend, not a full press-up: -5/-14/-8.
Small constant forward `upperarm` flexion represents the propped elbows
("elbows under your shoulders").

Flagged `animationIsApproximate` in SeedData.json — this one substitutes a
different overall body position (standing vs. actually lying prone on the
floor), a bigger simplification than most other approximate-but-unflagged
poses in this family, so the disclaimer earns its keep here specifically
(same bar as reverse_prayer_stretch, the only other flagged exercise so
far).

Highlight: Abs + Lower Back, matching the exercise's target tags.
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
EXERCISE = "sphinx_pose"
VIDEO_NAME = "sphinx_pose.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.25

WORKED_KEYWORDS = ("abs", "lower back")

_ELBOWS = {"upperarm.L": (r(-15), 0, 0), "upperarm.R": (r(-15), 0, 0)}

POSES = {
    0: {},
    30: {**_ELBOWS, "chest": (r(-6), 0, 0)},
    60: {**_ELBOWS, "spine": (r(-5), 0, 0), "chest": (r(-14), 0, 0), "head": (r(-8), 0, 0)},
    90: {**_ELBOWS, "spine": (r(-5), 0, 0), "chest": (r(-14), 0, 0), "head": (r(-8), 0, 0)},
    120: {},
}

L.run(globals())
