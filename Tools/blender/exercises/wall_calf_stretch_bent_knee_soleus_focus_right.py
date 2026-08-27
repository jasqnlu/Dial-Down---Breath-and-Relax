"""Wall Calf Stretch, Bent-Knee Soleus Focus (Right) — mirror of the left version.

See wall_calf_stretch_bent_knee_soleus_focus_left.py's docstring.

Highlight: Right Calves.
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
EXERCISE = "wall_calf_stretch_bent_knee_soleus_focus_right"
VIDEO_NAME = "wall_calf_stretch_bent_knee_soleus_focus_right.mp4"

CAMERA_AZIMUTH = 90
WORKED_KEYWORDS = (['right calve'])

POSES = {
    0:   {},
    30:  {"thigh.L": (r(6), 0, 0), "thigh.R": (r(-6), 0, 0),
          "upperarm.L": (r(-40), 0, 0), "upperarm.R": (r(-40), 0, 0)},
    60:  {"thigh.L": (r(10), 0, 0), "shin.L": (r(-10), 0, 0),
          "thigh.R": (r(-10), 0, 0), "shin.R": (r(16), 0, 0), "spine": (r(6), 0, 0),
          "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    90:  {"thigh.L": (r(10), 0, 0), "shin.L": (r(-10), 0, 0),
          "thigh.R": (r(-10), 0, 0), "shin.R": (r(16), 0, 0), "spine": (r(6), 0, 0),
          "upperarm.L": (r(-70), 0, 0), "upperarm.R": (r(-70), 0, 0)},
    120: {},
}

L.run(globals())
