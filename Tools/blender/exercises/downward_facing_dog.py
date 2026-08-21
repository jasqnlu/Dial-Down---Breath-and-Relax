"""Downward-Facing Dog — muscle-body + skin-head animation.

Batch 14. "Hips lifted up and back, legs straight, inverted V, hands and
heels toward the floor." The rig's quadruped base (`apply_quadruped_base`)
is built for a KNEELING hands-and-knees pose (bent thighs/shins) and its
hip-drop is a fixed object-level translation, not something that can lift
the pelvis independent of a bent-knee stance — there's no clean way to
raise the hips above a straight-legged standing pose on this rig. Instead
approximated as a very deep STANDING forward fold (legs straight, the
`run()` base pose) — much deeper than standing_forward_fold_ragdoll.py's
75-degree cumulative pitch — with arms reaching far down past the proven
overhead-reach magnitudes, standing in for hands pressed into the floor.
This reads as "chest toward thighs, arms extended down" but does not
capture the raised-hip inverted-V silhouette; flagged
`animationIsApproximate` for that reason.

Highlight: both Hamstrings + both Calves + Spinal Erectors, matching the
exercise's core tags (Shoulders also tagged but the torso/leg fold is the
dominant visual).
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
EXERCISE = "downward_facing_dog"
VIDEO_NAME = "downward_facing_dog.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.5

WORKED_KEYWORDS = ("hamstring", "calve", "spinal erector")

POSES = {
    0: {},
    30: {
        "spine": (r(35), 0, 0), "chest": (r(25), 0, 0),
        "upperarm.L": (r(-60), 0, 0), "upperarm.R": (r(-60), 0, 0),
    },
    60: {
        "spine": (r(55), 0, 0), "chest": (r(40), 0, 0), "head": (r(10), 0, 0),
        "upperarm.L": (r(-95), 0, 0), "upperarm.R": (r(-95), 0, 0),
    },
    90: {
        "spine": (r(55), 0, 0), "chest": (r(40), 0, 0), "head": (r(10), 0, 0),
        "upperarm.L": (r(-95), 0, 0), "upperarm.R": (r(-95), 0, 0),
    },
    120: {},
}

L.run(globals())
