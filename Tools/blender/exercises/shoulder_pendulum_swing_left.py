"""Shoulder Pendulum Swing (Left) — muscle-body + skin-head animation.

New batch (2026-08-27). "Lean forward, support with the right hand on a
chair, let the left arm hang loose, swing it in small passive circles."
A small forward `spine` lean plants the support arm (`upperarm.R`, braced
forward), while the working arm (`upperarm.L`) swings through a small
circular path across the 4 keyframes — the same lazy-circle 4-key idea
proven in wrist_circles.py, applied to the shoulder axis instead of the
forearm.

No chair/support prop exists on this rig, so the braced hand is approximated as a still forward reach rather than true contact. Flagged `animationIsApproximate`.

**Re-audited (2026-09-05): the original render was a no-op.** Diagnosed via a
rest/mid/peak contact sheet — the working arm's swing (20-35deg pitch, 10-15deg
twist) rendered as visually indistinguishable frames from a side camera
(azimuth 90), because the L arm hangs near the torso silhouette's edge and the
static R support arm (raised -70deg, extended toward camera) dominates the
frame. Fixed by (1) roughly doubling the swing amplitude so it reads as an
actual pendulum rather than a static hang, and (2) rotating the camera to a
3/4 oblique (azimuth 40) so the swinging arm has open background behind it
instead of overlapping the torso outline. Confirmed real motion via a
rest/peak pixel diff after the fix.

Highlight: Left Shoulder + Left Shoulder Joint.
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
EXERCISE = "shoulder_pendulum_swing_left"
VIDEO_NAME = "shoulder_pendulum_swing_left.mp4"

CAMERA_AZIMUTH = 40
ORTHO_SCALE_MULT = 1.25
WORKED_KEYWORDS = (['left shoulder'])

POSES = {
    0:   {"spine": (r(20), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    30:  {"spine": (r(20), 0, 0), "upperarm.R": (r(-70), 0, 0),
          "upperarm.L": (r(40), 0, r(20))},
    60:  {"spine": (r(20), 0, 0), "upperarm.R": (r(-70), 0, 0),
          "upperarm.L": (r(65), r(25), r(-20))},
    90:  {"spine": (r(20), 0, 0), "upperarm.R": (r(-70), 0, 0),
          "upperarm.L": (r(40), 0, r(20))},
    120: {"spine": (r(20), 0, 0), "upperarm.R": (r(-70), 0, 0)},
}

L.run(globals())
