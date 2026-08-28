"""Left Doorway External Rotation Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Tier B item (rotation-audit backlog, 2026-08-10). Originally scoped as needing
an unproven `upperarm` local-Y twist convention — but re-reading the actual
instructions changed that: "Stand facing a doorframe and bend your elbow 90
degrees, forearm against the frame, upper arm at your side. Keeping your
elbow pinned to your side, rotate your body away from the frame." The arm
itself doesn't move relative to the torso at all — it stays pinned (elbow at
side, forearm fixed forward against the frame) while the TORSO does the
rotating. That's mechanically identical to left_wall_bicep_stretch.py's
already-proven `chest`/`spine` local-Y twist against a static arm pose, just
with the elbow bent 90 (forearm forward, pinned to an imaginary doorframe)
instead of the arm extended back against a wall.

Sign: the doorframe is in front of the LEFT arm; "rotate away from the frame"
for a left-pinned arm means twisting to the subject's own right, which is
NEGATIVE local-Y — same convention already verified for
left_wall_bicep_stretch.py (see that script's docstring / Finding 4 in
2026-08-05-rotation-animation-audit.md for the sign derivation).

Targets the anterior/front-outer shoulder (subscapularis, anterior deltoid)
per the exercise's own "front-outer left shoulder" callout — both live under
the "Left Shoulder" muscle group in the atlas.
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
EXERCISE = "left_doorway_external_rotation_stretch"
VIDEO_NAME = "left_doorway_external_rotation_stretch.mp4"

# 3/4 view — shows both the pinned forearm and the torso twist, unlike the
# full side profile Wall Bicep Stretch uses (where the arm-reach-back
# silhouette is the whole story; here the torso twist is).
CAMERA_AZIMUTH = 40

WORKED_KEYWORDS = ("left shoulder",)

# Elbow pinned at the side, forearm bent forward against the (unrendered)
# doorframe — held constant across every frame, same pattern as the seated
# leg pose. Only the torso twists.
_ARM = {
    "upperarm.L": (0, 0, 0),
    "forearm.L": (r(-90), 0, 0),
}

POSES = {
    0: dict(_ARM),
    30: {**_ARM, "chest": (0, r(-6), 0)},
    60: {**_ARM, "chest": (0, r(-16), 0), "spine": (0, r(-9), 0)},
    90: {**_ARM, "chest": (0, r(-16), 0), "spine": (0, r(-9), 0)},
    120: dict(_ARM),
}

L.run(globals())
