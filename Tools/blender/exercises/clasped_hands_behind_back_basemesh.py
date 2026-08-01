"""Clasped Hands Behind Back stretch on the FinalBaseMesh (A-pose base mesh).

PASTE-IN SCRIPT — run in Blender's *Scripting* tab, fresh/expendable .blend
(it CLEARS THE SCENE).

Why this mesh vs. the anatomy shell: FinalBaseMesh is a clean, single-manifold
human in an A-POSE (arms held down-and-out with air between arm and torso).
That gap is what stops distance-based skin weights from bleeding torso skin
onto the arm bones — the tearing we saw on the welded anatomy shell.

Pipeline:
  1. Wipe scene, import FinalBaseMesh.obj (importer maps its Y-up -> Blender
     Z-up), recenter to floor + centreline.
  2. DETECT landmarks from the geometry (hands, shoulders, hips, feet) so the
     armature fits this specific mesh instead of hardcoded coordinates.
  3. Build an A-pose-aware armature: arm bones run along the real shoulder->
     hand diagonal.
  4. Distance-skin every vertex (nearest-segment, inverse-distance blend over
     the TOP_K nearest bones) — 100% coverage, exportable skin, no bone-heat.
  5. Keyframe the clasped-hands-behind-back loop (f0..f120) and export .glb +
     .blend to Tools/blender/generated/exercises/.

Tunables: FACING (which way is "behind"), POSES angles, SKIN_POWER/TOP_K.
Results + any error surface as an in-Blender popup and a *_log.txt file.
"""
import bpy
import math
import os
import traceback
from mathutils import Vector, Euler

r = math.radians

REPO = "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
SRC_OBJ = os.path.join(REPO, "Tools/blender/incoming/FinalBaseMesh.obj")
OUT_DIR = os.path.join(REPO, "Tools/blender/generated/exercises")
EXERCISE = "clasped_hands_behind_back_basemesh"

FPS = 30
FRAME_END = 120

# Body front faces -Y (Blender default), so "behind the back" is +Y.
FACING = 1.0

# Distance-skinning tuning (see skin_by_distance).
SKIN_POWER = 3.5
SKIN_TOP_K = 2

# --- On-screen logging (double-clicked Blender has no visible console) -------
_LOG = []


def log(msg):
    _LOG.append(str(msg))
    print(msg)


def show_popup(title, icon):
    def draw(self, _ctx):
        for line in _LOG:
            for chunk in (line.splitlines() or [""]):
                self.layout.label(text=chunk)
    try:
        bpy.context.window_manager.popup_menu(draw, title=title, icon=icon)
    except Exception:
        pass


def write_log_file():
    try:
        os.makedirs(OUT_DIR, exist_ok=True)
        with open(os.path.join(OUT_DIR, f"{EXERCISE}_log.txt"), "w") as f:
            f.write("\n".join(_LOG) + "\n")
    except Exception:
        pass


def ensure_object_mode():
    if bpy.context.object is not None and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')


def clear_scene():
    ensure_object_mode()
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials):
        for block in list(coll):
            if block.users == 0:
                coll.remove(block)


def import_and_prep():
    if not os.path.exists(SRC_OBJ):
        raise SystemExit(f"Model not found: {SRC_OBJ!r}")
    if hasattr(bpy.ops.wm, "obj_import"):
        bpy.ops.wm.obj_import(filepath=SRC_OBJ)
    else:
        bpy.ops.import_scene.obj(filepath=SRC_OBJ)
    meshes = [o for o in bpy.context.selected_objects if o.type == 'MESH']
    if not meshes:
        meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = "Body"
    # Bake any import transform, then recenter feet to floor + X/Y to centre so
    # v.co == world and landmark math is in one clean space.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    cs = [Vector(c) for c in body.bound_box]  # already world (identity now)
    lo = Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs)))
    hi = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))
    body.location -= Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    return body


def detect_landmarks(body):
    """Find hands/shoulders/hips/feet from the mesh so bones fit THIS model."""
    vs = [v.co.copy() for v in body.data.vertices]
    zmin = min(v.z for v in vs)
    zmax = max(v.z for v in vs)
    H = zmax - zmin

    def band(frac_lo, frac_hi, pred=None):
        lo, hi = zmin + H * frac_lo, zmin + H * frac_hi
        return [v for v in vs if lo <= v.z < hi and (pred is None or pred(v))]

    # Hands: the lateral-most vertices (A-pose arms reach out to the sides).
    hand_R = max(vs, key=lambda v: v.x)   # +X side
    hand_L = min(vs, key=lambda v: v.x)   # -X side
    hand_x = (abs(hand_R.x) + abs(hand_L.x)) / 2
    hand_z = (hand_R.z + hand_L.z) / 2

    # Shoulder joint: torso half-width high on the trunk, excluding the arms
    # (keep only vertices well inside the hand reach).
    up_torso = band(0.78, 0.86, pred=lambda v: abs(v.x) < 0.55 * hand_x)
    shoulder_x = max((abs(v.x) for v in up_torso), default=0.14 * H) * 0.95
    shoulder_z = zmin + H * 0.82

    # Hips / leg roots: half the distance between the two legs at mid-thigh.
    thigh_band = band(0.44, 0.50)
    right_leg = [v.x for v in thigh_band if v.x > 0]
    left_leg = [v.x for v in thigh_band if v.x < 0]
    hip_x = (min(right_leg) + abs(max(left_leg))) / 2 if right_leg and left_leg else 0.09 * H
    hip_x = max(hip_x, 0.05 * H)

    # Feet centre X per side (near the floor).
    foot_band = band(0.0, 0.04)
    fr = [v.x for v in foot_band if v.x > 0]
    fl = [v.x for v in foot_band if v.x < 0]
    foot_x = (sum(fr) / len(fr) + abs(sum(fl) / len(fl))) / 2 if fr and fl else hip_x

    lm = {
        "H": H, "zmin": zmin, "zmax": zmax,
        "hand_x": hand_x, "hand_z": hand_z,
        "shoulder_x": shoulder_x, "shoulder_z": shoulder_z,
        "hip_x": hip_x, "foot_x": foot_x,
    }
    log("landmarks: " + ", ".join(
        f"{k}={round(v, 2)}" for k, v in lm.items()))
    return lm


def build_armature(lm):
    H, zmin = lm["H"], lm["zmin"]

    def z(frac):
        return zmin + frac * H

    sx, sz = lm["shoulder_x"], lm["shoulder_z"]
    hx, hz = lm["hand_x"], lm["hand_z"]
    # Elbow = midpoint of the shoulder->hand diagonal (A-pose arm is ~straight).
    ex = (sx + hx) / 2
    ez = (sz + hz) / 2
    hipx, footx = lm["hip_x"], lm["foot_x"]

    bones = [
        ("hips",       (0, 0, z(0.50)),  (0, 0, z(0.56)), None),
        ("spine",      (0, 0, z(0.56)),  (0, 0, z(0.70)), "hips"),
        ("chest",      (0, 0, z(0.70)),  (0, 0, z(0.82)), "spine"),
        ("head",       (0, 0, z(0.86)),  (0, 0, z(0.98)), "chest"),
        ("upperarm.L", (-sx, 0, sz),     (-ex, 0, ez), "chest"),
        ("forearm.L",  (-ex, 0, ez),     (-hx, 0, hz), "upperarm.L"),
        ("upperarm.R", (sx, 0, sz),      (ex, 0, ez), "chest"),
        ("forearm.R",  (ex, 0, ez),      (hx, 0, hz), "upperarm.R"),
        ("thigh.L",    (-hipx, 0, z(0.50)), (-hipx, 0, z(0.28)), "hips"),
        ("shin.L",     (-hipx, 0, z(0.28)), (-footx, 0, z(0.04)), "thigh.L"),
        ("thigh.R",    (hipx, 0, z(0.50)),  (hipx, 0, z(0.28)), "hips"),
        ("shin.R",     (hipx, 0, z(0.28)),  (footx, 0, z(0.04)), "thigh.R"),
    ]

    arm_data = bpy.data.armatures.new("Rig")
    arm_obj = bpy.data.objects.new("Rig", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='EDIT')
    ebs = {}
    for name, head, tail, _p in bones:
        eb = arm_data.edit_bones.new(name)
        eb.head = Vector(head)
        eb.tail = Vector(tail)
        eb.use_deform = True
        ebs[name] = eb
    for name, _h, _t, parent in bones:
        if parent:
            ebs[name].parent = ebs[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj


def _closest_on_segment(p, a, b):
    ab = b - a
    denom = ab.length_squared
    if denom < 1e-12:
        return a.copy()
    t = max(0.0, min(1.0, (p - a).dot(ab) / denom))
    return a + ab * t


def bind(body, arm_obj):
    """Distance-based skinning: nearest-segment inverse-distance over TOP_K."""
    mod = body.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    body.parent = arm_obj
    body.matrix_parent_inverse = arm_obj.matrix_world.inverted()

    bones = [(b.name, b.head_local.copy(), b.tail_local.copy())
             for b in arm_obj.data.bones if b.use_deform]
    groups = {name: (body.vertex_groups.get(name) or body.vertex_groups.new(name=name))
              for name, _h, _t in bones}

    verts = body.data.vertices
    for v in verts:
        p = v.co
        dists = [((p - _closest_on_segment(p, h, t)).length, name)
                 for name, h, t in bones]
        dists.sort(key=lambda d: d[0])
        ws = [(name, 1.0 / (d ** SKIN_POWER + 1e-9)) for d, name in dists[:SKIN_TOP_K]]
        s = sum(w for _n, w in ws) or 1.0
        for name, w in ws:
            groups[name].add([v.index], w / s, 'REPLACE')
    log(f"bind: distance skinning -> {len(verts)}/{len(verts)} verts "
        f"(power={SKIN_POWER}, top_k={SKIN_TOP_K})")


# --- The stretch, per-frame bone euler rotations (radians, bone-local). ------
# Rest is the A-POSE (arms already out). Clasped-hands-behind-back brings the
# arms down/back/together behind the trunk. FIRST-PASS angles — tune visually.
POSES = {
    0: {},
    30: {
        "upperarm.L": (r(40) * FACING, 0, 0),
        "upperarm.R": (r(40) * FACING, 0, 0),
        "forearm.L":  (r(35) * FACING, 0, 0),
        "forearm.R":  (r(35) * FACING, 0, 0),
        "chest":      (r(-3) * FACING, 0, 0),
    },
    60: {
        "upperarm.L": (r(60) * FACING, 0, 0),
        "upperarm.R": (r(60) * FACING, 0, 0),
        "forearm.L":  (r(15) * FACING, 0, 0),
        "forearm.R":  (r(15) * FACING, 0, 0),
        "chest":      (r(8) * FACING, 0, 0),
        "head":       (r(5) * FACING, 0, 0),
    },
    90: {
        "upperarm.L": (r(60) * FACING, 0, 0),
        "upperarm.R": (r(60) * FACING, 0, 0),
        "forearm.L":  (r(15) * FACING, 0, 0),
        "forearm.R":  (r(15) * FACING, 0, 0),
        "chest":      (r(8) * FACING, 0, 0),
        "head":       (r(5) * FACING, 0, 0),
    },
    120: {},
}


def animate(arm_obj):
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = 0
    scene.frame_end = FRAME_END
    animated = set()
    for pose in POSES.values():
        animated.update(pose.keys())
    for frame, pose in POSES.items():
        for name in animated:
            pb = arm_obj.pose.bones.get(name)
            if pb is None:
                continue
            pb.rotation_mode = 'XYZ'
            pb.rotation_euler = Euler(pose.get(name, (0.0, 0.0, 0.0)))
            pb.keyframe_insert("rotation_euler", frame=frame)
    scene.frame_set(0)


def export():
    os.makedirs(OUT_DIR, exist_ok=True)
    glb_path = os.path.join(OUT_DIR, f"{EXERCISE}.glb")
    blend_path = os.path.join(OUT_DIR, f"{EXERCISE}.blend")
    bpy.ops.export_scene.gltf(filepath=glb_path, export_format='GLB',
                              export_animations=True, export_yup=True)
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    return glb_path, blend_path


def main():
    clear_scene()
    body = import_and_prep()
    lm = detect_landmarks(body)
    arm_obj = build_armature(lm)
    bind(body, arm_obj)
    animate(arm_obj)
    glb_path, blend_path = export()
    log(f"[{EXERCISE}] built + exported.")
    log(f"animated model : {glb_path}")
    log(f"editable scene : {blend_path}")
    log(f"frames         : 0..{FRAME_END} @ {FPS}fps ({FRAME_END / FPS:.1f}s)")


try:
    main()
    write_log_file()
    show_popup("Stretch exported ✓", 'CHECKMARK')
except BaseException as exc:
    log("")
    log(f"ERROR: {exc}")
    log(traceback.format_exc())
    write_log_file()
    show_popup("Script FAILED - see details", 'ERROR')
    raise
