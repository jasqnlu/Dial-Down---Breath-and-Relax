"""Seated Bicep Stretch on Chair Edge — muscle-body + skin-head animation.

Bilateral, upper-body-only variant of left_seated_behind_hip_bicep_stretch.py
— both palms planted behind the hips on a chair seat, elbows straight,
chest lifted. No leg re-pose (the rig's default stand reads fine for a
chair-edge perch; only the seated_hamstring/forward-fold family, where the
legs ARE the point of the stretch, override `thigh`/`shin`). Reuses the
proven `upperarm` local-X extension + local-Z adduction (mirrored) from the
wall/prayer bicep family, plus a small backward spine lean for "lift your
chest."

Highlight: Left Biceps + Right Biceps.
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
EXERCISE = "seated_bicep_stretch_on_chair_edge"
VIDEO_NAME = "seated_bicep_stretch_on_chair_edge.mp4"

CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left bicep", "right bicep")

POSES = {
    0: {},
    30: {
        "upperarm.L": (r(20), 0, r(8)),
        "upperarm.R": (r(20), 0, r(-8)),
    },
    60: {
        "upperarm.L": (r(38), 0, r(12)),
        "upperarm.R": (r(38), 0, r(-12)),
        "spine": (r(-6), 0, 0),
    },
    90: {
        "upperarm.L": (r(38), 0, r(12)),
        "upperarm.R": (r(38), 0, r(-12)),
        "spine": (r(-6), 0, 0),
    },
    120: {},
}

L.run(globals())
