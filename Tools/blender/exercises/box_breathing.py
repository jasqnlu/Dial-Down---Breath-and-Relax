"""Box Breathing — muscle-body + skin-head animation.

Breathing batch (2026-08-27), probe exercise. First use of the shared
pipeline's new `SCALE_POSES` channel (see `_lib.animate`'s docstring): every
prior composition only ever needed bone ROTATION, but breathing's motion is
the ribcage growing and shrinking in place, not rotating. Base: the ordinary
proven seated-chair fold (`run_seated`, unchanged leg convention), figure
sits still, `chest` bone pulses via isotropic pose-bone scale
1.0 -> 1.08 -> 1.0 across the loop (isotropic, not a directional axis pick,
because this rig's chest bone is a purely-vertical edit bone and its local
X/Z-vs-world mapping was never characterized for any prior composition —
isotropic sidesteps that ambiguity entirely and is still visible from any
camera angle, at the cost of not distinguishing "front" expansion from
"side" expansion). Side camera (azimuth 90) chosen anyway, matching the
recurring "camera plane must not foreshorten the working motion" lesson,
since a scale pulse is symmetric but a torso silhouette read is still
clearer from the side where the chest is the widest visible landmark
against open background.

Highlight: chest (the worked "muscle" for a diaphragmatic/chest-expansion
breath), matching Bridge Pose's precedent of tagging 'Left Chest'/'Right
Chest' via the same `group_to_bone` keyword rule.

Probe purpose: confirm the SCALE_POSES channel actually renders a visible
pulse before fanning out to the other 45 breathing exercises.
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
EXERCISE = "box_breathing"
VIDEO_NAME = "box_breathing.mp4"

CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("chest",)

_LEGS = {
    "thigh.L": (r(-90), 0, 0), "shin.L": (r(90), 0, 0),
    "thigh.R": (r(-90), 0, 0), "shin.R": (r(90), 0, 0),
}

# Rotation channel: legs held in the seated fold every frame, a very slight
# spine/head extension at peak inhale to reinforce the ribcage-rise read
# beyond the scale pulse alone.
POSES = {
    0:   {**_LEGS},
    60:  {**_LEGS, "spine": (r(-9), 0, 0), "head": (r(-6), 0, 0)},
    120: {**_LEGS},
}

# Scale channel: chest bone pulses isotropically for the inhale/exhale.
SCALE_POSES = {
    0:   {"chest": (1.0, 1.0, 1.0)},
    60:  {"chest": (1.13, 1.13, 1.13)},
    120: {"chest": (1.0, 1.0, 1.0)},
}

L.run_seated(globals())
