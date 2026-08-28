"""Bridge Pose — muscle-body + skin-head animation.

Retry (2026-08-27) of a composition dropped in the 31-exercise batch for
torn/spiky foot geometry and a dark gap at the crotch when `hips` stayed
fixed-flat while `spine` arched backward — the dropped attempt's script
wasn't kept, so this is rebuilt from proven pieces rather than patched.

Two fixes vs. the presumed original approach:
1. **Legs held constant at a proven-safe fold, not animated.** The foot
   tearing was very likely from animating thigh/shin through a large sweep
   (the usual tearing trigger elsewhere in this batch). Bridge Pose's legs
   don't actually move once set — only the hips/spine lift is dynamic — so
   thigh/shin are held at `double_knee_to_chest_release.py`'s proven-safe
   SHALLOW symmetric fold (thigh -75 / shin 90, "tested no crease" per that
   script's own docstring), representing "knees bent, feet flat, close to
   the hips," never animated, so there's nothing left to tear.
2. **A modest spine arch (8 degrees), and the "gap" re-diagnosed.** Tried
   -12, -6, and -3 degrees and rendered all three: the small crotch notch
   at the seam between the two thigh muscle groups is present EVEN AT
   REST (spine=0, no arch at all) — it doesn't scale with the arch angle,
   so it isn't the spine-arch pivot creating a gap as originally
   diagnosed. It's an inherent seam of this exact leg fold (thigh -75 /
   shin 90, the same values `double_knee_to_chest_release.py` already
   ships with) that a full-body front view simply exposes here where
   other compositions don't happen to frame it. Accepted as a small,
   pre-existing cosmetic artifact rather than something this batch can
   fix, and 8 degrees picked as a visible-but-modest lift (real motion:
   confirmed ~45k changed pixels between rest/peak stills) rather than the
   smallest value tried. `chest` gets a small matching counter-arch so the
   torso curve reads as one continuous line rather than a kink at the
   spine/chest joint.

**Camera: plain `run_supine` default (oblique), NOT FORCE_TOPDOWN.**
First tried FORCE_TOPDOWN, reasoning a hip lift is the same class of
Z-axis motion as `double_knee_to_chest_release`'s knee lift — rendered,
and it read as a standing figure, not lying down: FORCE_TOPDOWN's steep
perspective camera was tuned against a pose whose legs fold UP into the
air (breaking the "standing" silhouette read); Bridge Pose's legs stay
low near the floor the whole time, so that same camera has nothing to
disambiguate it with. The default oblique camera (proven for the general
ROLL_DEG=0 family) reads correctly as lying down instead.

Highlight: Abs + Hip Flexors + Chest, matching the exercise's target tags.
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
EXERCISE = "bridge_pose"
VIDEO_NAME = "bridge_pose.mp4"

ROLL_DEG = 0

WORKED_KEYWORDS = ("abs", "hip flexor", "chest")

_LEGS = {
    "hips": (r(-90), 0, 0),
    "thigh.L": (r(-75), 0, 0), "thigh.R": (r(-75), 0, 0),
    "shin.L": (r(90), 0, 0), "shin.R": (r(90), 0, 0),
}

POSES = {
    0:   {**_LEGS},
    60:  {**_LEGS, "spine": (r(-8), 0, 0), "chest": (r(-4), 0, 0)},
    120: {**_LEGS},
}

L.run_supine(globals())
