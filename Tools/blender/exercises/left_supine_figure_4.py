"""Left Supine Figure-4 Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Flat-on-the-back supine base (ROLL_DEG=0), same as the spinal twist scripts.
Instructions: "Lie on your back with knees bent... cross your LEFT ankle
over your RIGHT knee... reach through and clasp your hands behind your
right thigh, gently drawing both legs toward your chest."

This is the exercise the supine-pose probe originally couldn't ship: the
crossing ankle needed a large swing that stretched the convex-hulled foot
"mitt" into thin webbing. Root cause found 2026-08-09 (second follow-up):
mitts were weighted with the SAME joint-blend distance function as actual
stretchy muscle geometry (blend_weights), which pulls a large-swing mitt's
far vertices toward whichever second-nearest bone the blend picks at the
ROTATED pose — a rigid hull pulled by two competing weights is exactly what
tears. Fixed generally in _lib.py: hulled mitts now get rigid_weight() (100%
to their one owning bone, no distance blending) instead of blend_weights().
Confirmed by rendering: the same -45 to -60 degree shin swing that produced
webbing before now holds its shape through the whole range.

Getting the swing angle to NOT tear was the hard part; getting it to read
as an anatomically clean "figure-4" (ankle resting ON the opposite knee,
not just crossing near the shin) took another several rendered iterations
of hand-tuning thigh/shin angles together — the crossing leg needs BOTH the
thigh externally rotated (opens the knee out to the side, the classic
figure-4 shape) AND the shin folded back, not just a shin swing alone
(tried shin-only first; reads as a kick, not a cross). The values below are
the best rendered result this session, not a numerically-derived pose —
call it a reasonable approximation, not a precise ankle-on-knee contact.
Arms are kept in a relaxed forward position rather than animating the
"reach through and clasp" hand detail, which would need the hands to find
a specific point on the opposite thigh — out of scope for this pass.
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
EXERCISE = "left_supine_figure_4"
VIDEO_NAME = "left_supine_figure_4.mp4"

ROLL_DEG = 0  # flat on the back, no side roll

WORKED_KEYWORDS = ("left glutes",)

_ARMS_REST = {
    "upperarm.L": (r(-30), 0, 0),
    "upperarm.R": (r(-30), 0, 0),
}
_RIGHT_LEG = {
    "thigh.R": (r(-90), 0, 0),
    "shin.R": (r(90), 0, 0),
}
_LEFT_BENT = {
    "thigh.L": (r(-90), 0, 0),
    "shin.L": (r(90), 0, 0),
}
_LEFT_CROSSED = {
    "thigh.L": (r(-90), 0, r(-55)),
    "shin.L": (r(100), 0, r(10)),
}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_RIGHT_LEG, **_LEFT_BENT, **_ARMS_REST},
    30:  {"hips": (r(-90), 0, 0), **_RIGHT_LEG,
          "thigh.L": (r(-90), 0, r(-28)), "shin.L": (r(95), 0, r(5)), **_ARMS_REST},
    60:  {"hips": (r(-90), 0, 0), **_RIGHT_LEG, **_LEFT_CROSSED, **_ARMS_REST},
    90:  {"hips": (r(-90), 0, 0), **_RIGHT_LEG,
          "thigh.L": (r(-90), 0, r(-28)), "shin.L": (r(95), 0, r(5)), **_ARMS_REST},
    120: {"hips": (r(-90), 0, 0), **_RIGHT_LEG, **_LEFT_BENT, **_ARMS_REST},
}

L.run_supine(globals())
