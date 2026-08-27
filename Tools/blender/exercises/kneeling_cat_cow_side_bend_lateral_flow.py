"""Kneeling Cat-Cow Side Bend (Lateral Flow) — muscle-body + skin-head animation.

60-exercise batch. Quadruped hands-and-knees base (apply_quadruped_base, same rest angles as frog_stretch_kneeling_groin_stretch.py) with a small `spine`/`chest` local-Z side bend layered on the forward-pitched spine -- a NEW composition (Z side-bend has only been proven on a VERTICAL spine before; here the spine is already pitched ~95deg forward). Kept deliberately small (12deg) since this is untested territory for a pitched-then-bent compound rotation, the same caution class as the supine twist-composition failure documented in the handoff.

Highlight: Left Obliques, Right Obliques.
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
EXERCISE = "kneeling_cat_cow_side_bend_lateral_flow"
VIDEO_NAME = "kneeling_cat_cow_side_bend_lateral_flow.mp4"

WORKED_KEYWORDS = ("oblique",)

_BASE = {
    "spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": (r(-10), 0, 0),
    "upperarm.L": (r(-68), 0, 0), "forearm.L": (r(25), 0, 0),
    "upperarm.R": (r(-68), 0, 0), "forearm.R": (r(25), 0, 0),
    "thigh.L": (r(5), 0, 0), "shin.L": (r(100), 0, 0),
    "thigh.R": (r(5), 0, 0), "shin.R": (r(100), 0, 0),
}

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.35

POSES = {
    0:   {**_BASE},
    30:  {**_BASE, "spine": (r(95), 0, r(-12)), "chest": (r(-5), 0, r(-6))},
    60:  {**_BASE},
    90:  {**_BASE, "spine": (r(95), 0, r(12)), "chest": (r(-5), 0, r(6))},
    120: {**_BASE},
}

L.run_quadruped(globals())
