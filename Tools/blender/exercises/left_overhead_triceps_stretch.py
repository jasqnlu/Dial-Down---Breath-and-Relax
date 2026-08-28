"""Left Overhead Triceps Stretch — muscle-body + skin-head animation.

Sixth batch, exercise #3. "Raise your arm overhead and bend the elbow,
letting your hand drop behind your head." New shape for this rig — every
prior overhead reach (chest-opener, wall/doorway bicep, reach-through-twist)
keeps the arm straight or near-straight; this is the first to combine a deep
overhead upperarm flexion WITH a large separate forearm fold on top of it.

Both bones use the same proven `local-X` axis (Gotcha #6's "-X = forward"
for upperarm, "-X = elbow flexion" for forearm) — since neither bone's pose
carries a Y or Z component, both rotate about the SAME fixed world-X axis
(rotating about your own local X doesn't move that axis), so their angles
ADD into one total rotation: the forearm SEGMENT's own direction is
`dir(upperarm_deg + forearm_deg)` applied to its rest-down orientation, not
just the forearm's own angle in isolation. First attempt used `upperarm
-160, forearm -70` (total -230, which points mostly up-and-behind) and
rendered with the hand still reaching straight up past the head — not
"dropped behind" at all. Solving for a total near +50 (whose direction
`(0, sin50, -cos50)` points behind AND down, i.e. back toward the head/neck
from an elbow already up near head height) meant a much bigger forearm
fold: `upperarm -160 + forearm -150 = -310 ≡ +50`. Rendered clean — the
hand/mitt lands right behind the skull, matching the instruction.

The "other hand presses the elbow" detail is not animated (right arm stays
at rest) — same simplification as the family's other secondary-hand details
(no hand-target IK in this pipeline).

Highlight: Left Triceps, the muscle named in the exercise's own title.
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
EXERCISE = "left_overhead_triceps_stretch"
VIDEO_NAME = "left_overhead_triceps_stretch.mp4"

# Side view — an overhead-and-behind arm silhouette reads best from the side,
# same reasoning as the doorway/wall bicep family.
CAMERA_AZIMUTH = 90

WORKED_KEYWORDS = ("left tricep",)

POSES = {
    0:   {},
    30:  {"upperarm.L": (r(-90), 0, 0), "forearm.L": (r(-60), 0, 0)},
    60:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    90:  {"upperarm.L": (r(-160), 0, 0), "forearm.L": (r(-150), 0, 0)},
    120: {},
}

L.run(globals())
