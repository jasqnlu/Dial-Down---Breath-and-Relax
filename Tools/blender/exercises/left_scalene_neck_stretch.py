"""Left Scalene Neck Stretch — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

Fourth batch (Tier A of the rotation audit), exercise #5. Combines all THREE
head axes at once — the first script to do so. Each is individually proven
(X pitch: neck_flexion/neck_extension; Z side bend: the standing side bends;
Y twist: the seated spinal twists), but the three-way combination is new, so
the render is eyeballed rather than trusted from the sanity log.

Mapping the instructions to axes:
  * "Tilt your head to the RIGHT, bringing your right ear toward your right
    shoulder" -> +Z (positive local-Z bends toward the subject's own right).
    This is the dominant motion and gets the largest angle.
  * "Rotate your chin slightly UPWARD" -> -X (negative pitches the chin up,
    per neck_extension_look_up.py).
  * "...and toward the RIGHT side" -> -Y. **Sign correction (2026-08-20):**
    originally shipped as +Y on the (wrong) belief that positive twists
    toward the subject's own right — see
    left_levator_scapulae_stretch.py's docstring for the numeric probe that
    settled it: the head bone follows the same "+Y = subject's own left"
    convention as chest/spine, it was never a bone-specific exception.
A LEFT-named stretch tilting right is the app's usual bilateral convention:
the name is the side being STRETCHED, not the direction of travel.

Both chin components are deliberately small ("slightly" in the instructions) —
the scalenes are stretched mostly by the lateral tilt, and overcooking the
twist would read as a neck rotation instead.

Highlight: the scalenes are anterior-lateral neck muscles, so Front Neck is
the right group (Back Neck would be the chin-to-chest family). The atlas has
no sided neck groups, so Left Trapezius supplies the side specificity.

NOT seated — this exercise's own instructions say "Sit OR stand tall", so the
rig's default standing rest stance is faithful and avoids the knee-crease
geometry the seated pose introduces.
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
EXERCISE = "left_scalene_neck_stretch"
VIDEO_NAME = "left_scalene_neck_stretch.mp4"

# Mostly front-on (the lateral tilt is the dominant motion and reads best
# face-on), nudged off-axis so the chin-up-and-across component is visible.
CAMERA_AZIMUTH = 25

WORKED_KEYWORDS = ("front neck", "left trapezius")

POSES = {
    0: {},
    30: {"head": (r(-4), r(-8), r(14))},
    60: {"head": (r(-8), r(-15), r(30))},
    90: {"head": (r(-8), r(-15), r(30))},
    120: {},
}

L.run(globals())
