"""Neck Flexion Stretch (Chin-to-Chest) — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift — this
Blender build has no FFMPEG).

First of the second batch of exercises built on the shared `_lib.py` pipeline
(generalized from clasped_hands_behind_back_muscleonly.py, exercise #1). See
ANIMATION_HANDOFF.md's "Second batch" section for the walkthrough — this
script is the simplest possible case: ONE bone (head), ONE rotation axis.

Pose: chin lowers toward the chest. Bone-axis convention for the VERTICAL
bones (head/chest/spine, which point straight up, unlike the arm bones that
hang down) was solved numerically (see the handoff): local X rotation pitches
the bone toward front (-Y world) — i.e. **positive local-X = forward pitch**
for head/chest/spine. Confirmed via a probe script that read world tail
position after a +20 deg local-X rotation (moved -Y and slightly -Z, exactly
"nod forward"). This is the OPPOSITE sign convention from the arm bones
(which hang down and use +X = swing BACK) — don't reuse the arm sign here.
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
EXERCISE = "neck_flexion_chin_to_chest"
VIDEO_NAME = "neck_flexion_chin_to_chest.mp4"

# Side view reads a forward head-nod far better than front (a front camera
# looks straight at the -Y pitch direction, so the tilt reads as foreshortening
# instead of motion). 90 = right side, level with the standing figure.
CAMERA_AZIMUTH = 90

# Only "Back Neck" is targeted (the stretch, not the whole neck) — this app
# atlas has separate Front Neck / Back Neck muscle objects.
WORKED_KEYWORDS = ("back neck",)

POSES = {
    0: {},
    30: {"head": (r(15), 0, 0)},
    60: {"head": (r(35), 0, 0)},
    90: {"head": (r(35), 0, 0)},
    120: {},
}

L.run(globals())
