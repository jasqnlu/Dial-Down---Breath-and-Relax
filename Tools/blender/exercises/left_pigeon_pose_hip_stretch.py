"""Left Pigeon Pose Hip Stretch — muscle-body + skin-head animation.

60-exercise batch. Same pose as pigeon_pose_left_leg_forward.py (a quadruped-entry phrasing of the same Pigeon Pose shape). NOTE: this exercise's own SeedData targetBodyParts tag reads ['Left Glutes', 'Left Hip Flexors'], but its OWN instructions say the stretch is felt "through your left glute and the front of your RIGHT hip" (the extended-back leg) -- the tag looks like a copy/paste bug (should be Right Hip Flexors, matching pigeon_pose_left_leg_forward.py's tag for the identical pose). Highlighting the anatomically-correct Right Hip Flexors here per the written instructions, not the tag; flagged for a content fix separately.

Highlight: Left Glutes, Right Hip Flexors.
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
EXERCISE = "left_pigeon_pose_hip_stretch"
VIDEO_NAME = "left_pigeon_pose_hip_stretch.mp4"

WORKED_KEYWORDS = ("left glutes", "right hip")

_LEGS = {
    "thigh.L": (r(-90), 0, -r(30)), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(15), 0, 0), "shin.R": (r(100), 0, 0),
}

CAMERA_AZIMUTH = 100
ORTHO_SCALE_MULT = 1.5
SEATED_DROP = 0.50

POSES = {
    0:   {**_LEGS},
    30:  {**_LEGS, "spine": (r(10), 0, 0)},
    60:  {**_LEGS, "spine": (r(22), 0, 0), "chest": (r(15), 0, 0)},
    90:  {**_LEGS, "spine": (r(22), 0, 0), "chest": (r(15), 0, 0)},
    120: {**_LEGS},
}

L.run_seated(globals())
