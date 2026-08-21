"""Legs Up the Wall — muscle-body + skin-head animation.

Eighth batch, exercise #5. First exercise to raise the legs to fully
VERTICAL from the supine base. `thigh.{L,R}` local-X = -90 (the same
"-X = forward/up" sign already proven for hip flexion) rotates the legs a
further 90 deg from the supine rest position (legs flat along the floor, in
line with the torso) to point straight up — perpendicular to the floor,
i.e. world-vertical. `shin` stays at 0 (straight, unbent), unlike the
knee-to-chest family's folded shins.

Camera: `run_supine_side`, NOT the family's usual top-down/oblique choice.
Those cameras look straight down world Z; once the legs point straight up
(also world Z), a topdown-style camera would stare straight down the legs'
own length axis and foreshorten them to invisible dots — the exact
"working motion points at the camera" failure `run_supine_side` was
written for (see its docstring, and left_sleeper_stretch.py for the prior
use).

First attempt used `CAMERA_AZIMUTH = 0`, copying left_sleeper_stretch.py's
"0 views from directly in front" claim — but that claim is specific to a
ROLLED (side-lying) pose, where the roll has already moved the body's
front-facing direction into the plane `run_supine_side`'s camera orbits
(X/Z). This exercise stays flat (`ROLL_DEG = 0`, never rolled), so the
body's front still faces world +Z — exactly the axis camera azimuth 0
sits on (the camera math places it at `center + (0, 0, radius)`, looking
back down -Z) — and the leg swing (thigh rotating toward +Z, i.e. straight
up) points directly at that camera too, foreshortening away just like the
topdown camera would have. Rendered and confirmed nearly identical
rest/peak frames before catching this. Fixed by setting azimuth to 90
instead: `sin(90)=1, cos(90)=0` places the camera on the world X axis,
which views the Y-Z plane (the plane the leg swing actually happens in)
edge-on — rendered clean, legs visibly rise from flat to vertical.

Lesson: `run_supine_side`'s "0 = front" is only true once a ROLL_DEG has
repositioned the body's front-facing direction into the azimuth-orbit
plane; for a flat (unrolled) exercise, solve for the camera azimuth that's
perpendicular to the actual working motion, the same way every other
exercise's camera choice in this pipeline has always been solved, rather
than copying a sibling script's azimuth number by analogy.

Arms: "let your arms rest out to the sides, palms up" — a small constant
abduction on both `upperarm` (well under the ~45 deg tearing ceiling
documented for arm abduction) reads as "resting open" without risking the
cape-tear failure mode; omitting it entirely would leave the arms at their
raw (0,0,0) local rotation, which — now that the whole rig is tipped
supine — points them along the body's length rather than out to the sides.

Highlight: Hamstrings + Lower Back, matching the exercise's target tags.
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
EXERCISE = "legs_up_the_wall"
VIDEO_NAME = "legs_up_the_wall.mp4"

ROLL_DEG = 0
CAMERA_AZIMUTH = 90
ORTHO_SCALE_MULT = 1.3

WORKED_KEYWORDS = ("hamstring", "lower back")

_ARMS = {"upperarm.L": (0, 0, r(20)), "upperarm.R": (0, 0, r(-20))}

POSES = {
    0:   {"hips": (r(-90), 0, 0), **_ARMS,
          "thigh.L": (r(-45), 0, 0), "thigh.R": (r(-45), 0, 0)},
    30:  {"hips": (r(-90), 0, 0), **_ARMS,
          "thigh.L": (r(-70), 0, 0), "thigh.R": (r(-70), 0, 0)},
    60:  {"hips": (r(-90), 0, 0), **_ARMS,
          "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0)},
    90:  {"hips": (r(-90), 0, 0), **_ARMS,
          "thigh.L": (r(-90), 0, 0), "thigh.R": (r(-90), 0, 0)},
    120: {"hips": (r(-90), 0, 0), **_ARMS,
          "thigh.L": (r(-45), 0, 0), "thigh.R": (r(-45), 0, 0)},
}

L.run_supine_side(globals())
