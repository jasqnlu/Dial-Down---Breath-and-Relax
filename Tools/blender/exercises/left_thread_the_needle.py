"""Left Thread the Needle — muscle-body + skin-head animation.

PASTE-IN SCRIPT (Scripting tab, fresh/expendable .blend — it CLEARS THE SCENE),
also runs headless. Writes .glb + .blend + _log.txt + PNG renders to
Tools/blender/generated/exercises/, plus a PNG frame sequence for the baked
demo mp4 (encode separately with Tools/blender/encode_mp4.swift).

First quadruped (hands-and-knees) exercise — nothing in the rig had ever
been posed this way before (originally Tier A, moved to Tier B 2026-08-08:
"starts on hands and knees; no quadruped pose convention exists"). Base
pose derivation: `_lib.py`'s `apply_quadruped_base()`. Key finding: unlike
the supine base (a `hips` POSE-BONE rotation, since hips is the root and
its own head doesn't move under its own rotation), quadruped needs the
pelvis physically LOWERED — an OBJECT-level Z translation
(`arm_obj.location`), not a rotation. `spine` bends the torso forward to
horizontal (local-X ~95, the same "+X = forward pitch" convention already
proven elsewhere, just taken further); `thigh`/`shin` fold into a kneeling
stance; `upperarm`/`forearm` reach down to the floor. All angles found by
probe + render (bounds-driven algebra doesn't hold up: the floor-reach
angle for the arm is very sensitive because it inherits the torso's large
pitch, so a small forearm change produces a large world-space swing).

Instructions: "Start on hands and knees... slide your LEFT arm underneath
your body, palm up, lower your left shoulder and ear to the mat... keep
your right hand planted for support." The reach is `upperarm.L` swept well
past the floor-support angle (deep flexion, -140 vs the support arm's -68)
combined with a `chest`/`spine` twist (the already-proven local-Y
convention) so the left shoulder can drop. This is an approximation, not a
literal "hand slides through the gap under the torso" path — three passes
on the STANDING Reach-Through Twist already found cross-midline arm
adduction collides with the torso on this mesh (see ANIMATION_HANDOFF.md),
so this reach stays in front of the body rather than literally threading
underneath. Camera azimuth chosen empirically: this angle shows both the
reaching arm and the twisted/lowered shoulder-head.
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
EXERCISE = "left_thread_the_needle"
VIDEO_NAME = "left_thread_the_needle.mp4"

CAMERA_AZIMUTH = 330

WORKED_KEYWORDS = ("left shoulder", "left lats", "spinal erector")

# Constant quadruped base — never keyframed for these bones except spine,
# which needs its own per-frame entry because the twist rides on top of it
# (see animate()'s "any bone in ANY frame must be in EVERY frame" rule).
_LEGS = {
    "thigh.L": (r(5), 0, 0),
    "thigh.R": (r(5), 0, 0),
    "shin.L": (r(100), 0, 0),
    "shin.R": (r(100), 0, 0),
}
_HEAD_REST = (r(-10), 0, 0)
_RIGHT_ARM_PLANTED = {
    "upperarm.R": (r(-68), 0, 0),
    "forearm.R": (r(25), 0, 0),
}

POSES = {
    0:   {"spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": _HEAD_REST,
          "upperarm.L": (r(-68), 0, 0), "forearm.L": (r(25), 0, 0),
          **_LEGS, **_RIGHT_ARM_PLANTED},
    30:  {"spine": (r(95), r(-8), 0), "chest": (r(-5), r(-16), 0), "head": (r(-10), r(-10), 0),
          "upperarm.L": (r(-104), 0, r(-18)), "forearm.L": (r(18), 0, 0),
          **_LEGS, **_RIGHT_ARM_PLANTED},
    60:  {"spine": (r(95), r(-15), 0), "chest": (r(-5), r(-30), 0), "head": (r(-10), r(-20), 0),
          "upperarm.L": (r(-140), 0, r(-35)), "forearm.L": (r(10), 0, 0),
          **_LEGS, **_RIGHT_ARM_PLANTED},
    90:  {"spine": (r(95), r(-8), 0), "chest": (r(-5), r(-16), 0), "head": (r(-10), r(-10), 0),
          "upperarm.L": (r(-104), 0, r(-18)), "forearm.L": (r(18), 0, 0),
          **_LEGS, **_RIGHT_ARM_PLANTED},
    120: {"spine": (r(95), 0, 0), "chest": (r(-5), 0, 0), "head": _HEAD_REST,
          "upperarm.L": (r(-68), 0, 0), "forearm.L": (r(25), 0, 0),
          **_LEGS, **_RIGHT_ARM_PLANTED},
}

L.run_quadruped(globals())
