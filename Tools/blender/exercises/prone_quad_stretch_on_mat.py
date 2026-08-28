"""Prone Quad Stretch on Mat — muscle-body + skin-head animation.

60-exercise batch. Prone base (`hips` local-X=+90) with both shins folded deep (135, reusing side_lying_quad_stretch_with_strap's proven angle) to draw both heels toward the glutes, symmetric.

Highlight: Left Quadriceps, Right Quadriceps.
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
EXERCISE = "prone_quad_stretch_on_mat"
VIDEO_NAME = "prone_quad_stretch_on_mat.mp4"

WORKED_KEYWORDS = ("quadricep",)

ROLL_DEG = 0
CAMERA_AZIMUTH = 0
FORCE_TOPDOWN = True
ORTHO_SCALE_MULT = 1.3

_BASE = {"hips": (r(90), 0, 0)}

POSES = {
    0:   {**_BASE, "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
    30:  {**_BASE, "shin.L": (r(110), 0, 0), "shin.R": (r(110), 0, 0)},
    60:  {**_BASE, "shin.L": (r(135), 0, 0), "shin.R": (r(135), 0, 0)},
    90:  {**_BASE, "shin.L": (r(135), 0, 0), "shin.R": (r(135), 0, 0)},
    120: {**_BASE, "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0)},
}

L.run_supine(globals())
