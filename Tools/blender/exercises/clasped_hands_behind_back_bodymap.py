"""Run the "Clasped Hands Behind Back" stretch on the REAL Body-Map model.

PASTE-IN SCRIPT — run in Blender's *Scripting* tab (not headless), in a fresh
or expendable .blend, because it CLEARS THE CURRENT SCENE.

Difference vs. clasped_hands_behind_back.py (the block-figure prototype):
this one imports the app's shipped mesh (BodySkinMuscle.obj), fits an armature
to it, and binds with AUTOMATIC WEIGHTS so the welded skin bends smoothly — the
closest we can get to "watch the real body do the stretch" from a script.

Pipeline:
  1. Wipe the scene.
  2. Import BodySkinMuscle.obj and join skin + muscles into one "Body" mesh.
  3. Normalize orientation: rotate so the tallest axis is Z (up) and the widest
     horizontal axis is X (left-right). Self-calibrates regardless of how the
     importer mapped the file's axes.
  4. Build a ~12-bone humanoid armature FITTED to the measured bounds, placing
     each joint at an anatomical fraction of the measured height.
  5. Bind mesh -> armature with Automatic Weights (bone-heat). If that fails on
     the overlapping anatomy geometry, fall back to Envelope weights.
  6. Keyframe the same clasped-hands-behind-back loop (f0..f120).
  7. Export <OUT_DIR>/clasped_hands_behind_back_bodymap.glb + .blend and print
     the absolute paths.

TWO KNOBS TO TUNE BY EYE (rigging a real mesh always needs a visual pass):
  * FACING  — +1 or -1. If the arms swing FORWARD (in front) instead of behind
              the back, flip this sign.
  * POSES   — the per-frame joint angles below are a first pass; scrub the
              timeline and adjust.

NEXT STEP for the app: convert the .glb to .usdz for SceneKit/RealityKit.
"""
import bpy
import math
import os
import traceback
from mathutils import Vector, Euler, Matrix

r = math.radians

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
        pass  # popup can't show in some contexts; the log file still lands

# --- Paths. Edit APP_OBJ / OUT_DIR if your repo lives elsewhere. -------------
REPO = "/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
APP_OBJ = os.path.join(REPO, "Breath - Relax & Stretch/Resources/Models3D/BodySkinMuscle.obj")
OUT_DIR = os.path.join(REPO, "Tools/blender/generated/exercises")
EXERCISE = "clasped_hands_behind_back_bodymap"

FPS = 30
FRAME_END = 120

# Which way the figure faces along the depth (Y) axis. Flip to -1 if the arms
# end up swinging in FRONT of the body instead of behind it.
FACING = 1.0

# --- Anatomical landmarks as a fraction of total height (0 = feet, 1 = head) -
FR = {
    "feet": 0.02, "knee": 0.28, "hip": 0.50, "spine_top": 0.68,
    "chest_top": 0.80, "shoulder": 0.80, "neck": 0.84, "head_top": 1.00,
    "elbow": 0.615, "wrist": 0.44,
}
SHOULDER_X = 0.12   # half shoulder span, as a fraction of height
HIP_X = 0.055       # half hip span (leg roots), as a fraction of height

# --- The stretch, as per-frame bone euler rotations (radians, bone-local). ---
# Any bone omitted at a keyframe returns to (0,0,0), so f0/f120 give a clean
# neutral for a seamless loop. Angles are FIRST-PASS — tune by scrubbing.
POSES = {
    0: {},
    30: {   # arms swing behind the back, hands meet low (clasp)
        "upperarm.L": (r(35) * FACING, 0, r(-12)),
        "upperarm.R": (r(35) * FACING, 0, r(12)),
        "forearm.L":  (r(60) * FACING, 0, r(-20)),
        "forearm.R":  (r(60) * FACING, 0, r(20)),
        "chest":      (r(-4) * FACING, 0, 0),
    },
    60: {   # straighten + lift clasped hands, chest opens (peak stretch)
        "upperarm.L": (r(55) * FACING, 0, r(-6)),
        "upperarm.R": (r(55) * FACING, 0, r(6)),
        "forearm.L":  (r(18) * FACING, 0, r(-8)),
        "forearm.R":  (r(18) * FACING, 0, r(8)),
        "chest":      (r(10) * FACING, 0, 0),
        "head":       (r(6) * FACING, 0, 0),
    },
    90: {   # hold the peak
        "upperarm.L": (r(55) * FACING, 0, r(-6)),
        "upperarm.R": (r(55) * FACING, 0, r(6)),
        "forearm.L":  (r(18) * FACING, 0, r(-8)),
        "forearm.R":  (r(18) * FACING, 0, r(8)),
        "chest":      (r(10) * FACING, 0, 0),
        "head":       (r(6) * FACING, 0, 0),
    },
    120: {},
}


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


def import_obj(path):
    if not os.path.exists(path):
        raise SystemExit(f"OBJ not found: {path!r}")
    before = set(bpy.data.objects)
    if hasattr(bpy.ops.wm, "obj_import"):           # Blender 3.3+
        bpy.ops.wm.obj_import(filepath=path)
    else:                                           # legacy
        bpy.ops.import_scene.obj(filepath=path)
    new = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    if not new:
        raise SystemExit("Import produced no mesh objects.")
    return new


def join_into_body(meshes):
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = "Body"
    return body


def world_bounds(obj):
    cs = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs)))
    hi = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))
    return lo, hi


def normalize_orientation(body):
    """Rotate `body` so tallest axis -> Z (up), widest remaining -> X."""
    lo, hi = world_bounds(body)
    ext = hi - lo
    axes = sorted(range(3), key=lambda i: ext[i], reverse=True)  # big -> small
    up = axes[0]
    # of the two remaining axes, the wider one is left-right
    horiz = sorted(axes[1:], key=lambda i: ext[i], reverse=True)
    lr = horiz[0]
    depth = horiz[1]
    # Build a permutation matrix mapping current (lr, up, depth) -> (X, Z, Y).
    src = [lr, depth, up]           # -> Blender X, Y, Z
    R = Matrix.Identity(3)
    for dst_axis, s in enumerate(src):
        row = [0.0, 0.0, 0.0]
        row[s] = 1.0
        R[dst_axis] = row
    body.matrix_world = R.to_4x4() @ body.matrix_world
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Drop to floor + center horizontally so bone fractions line up with mesh.
    lo, hi = world_bounds(body)
    body.location -= Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    return world_bounds(body)


def build_armature(lo, hi):
    h = hi.z - lo.z
    z0 = lo.z

    def z(frac):
        return z0 + frac * h

    xs = SHOULDER_X * h
    xh = HIP_X * h

    # (name, head, tail, parent)
    bones = [
        ("hips",       (0, 0, z(FR["hip"])),        (0, 0, z(FR["hip"]) + 0.06 * h), None),
        ("spine",      (0, 0, z(FR["hip"]) + 0.06 * h), (0, 0, z(FR["spine_top"])), "hips"),
        ("chest",      (0, 0, z(FR["spine_top"])),  (0, 0, z(FR["chest_top"])), "spine"),
        ("head",       (0, 0, z(FR["neck"])),       (0, 0, z(FR["head_top"])), "chest"),
        ("upperarm.L", (xs, 0, z(FR["shoulder"])),  (xs, 0, z(FR["elbow"])), "chest"),
        ("forearm.L",  (xs, 0, z(FR["elbow"])),     (xs, 0, z(FR["wrist"])), "upperarm.L"),
        ("upperarm.R", (-xs, 0, z(FR["shoulder"])), (-xs, 0, z(FR["elbow"])), "chest"),
        ("forearm.R",  (-xs, 0, z(FR["elbow"])),    (-xs, 0, z(FR["wrist"])), "upperarm.R"),
        ("thigh.L",    (xh, 0, z(FR["hip"])),       (xh, 0, z(FR["knee"])), "hips"),
        ("shin.L",     (xh, 0, z(FR["knee"])),      (xh, 0, z(FR["feet"])), "thigh.L"),
        ("thigh.R",    (-xh, 0, z(FR["hip"])),      (-xh, 0, z(FR["knee"])), "hips"),
        ("shin.R",     (-xh, 0, z(FR["knee"])),     (-xh, 0, z(FR["feet"])), "thigh.R"),
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


# Skinning tuning: how sharply weight falls off with distance, and how many
# bones can influence one vertex. power ~3 keeps deformation fairly local;
# TOP_K=2 blends the two nearest bones so joints (elbow/shoulder/spine) bend
# smoothly instead of splitting.
SKIN_POWER = 3.0
SKIN_TOP_K = 2


def _closest_on_segment(p, a, b):
    ab = b - a
    denom = ab.length_squared
    if denom < 1e-12:
        return a.copy()
    t = max(0.0, min(1.0, (p - a).dot(ab) / denom))
    return a + ab * t


def bind(body, arm_obj):
    """Distance-based skinning.

    Bone-heat (ARMATURE_AUTO) silently produces EMPTY weight groups on this
    welded skin+muscle shell (overlapping/internal faces -> heat solve can't
    converge), which the glTF exporter then drops as "no skin". So we weight
    every vertex ourselves: nearest-segment distance to each bone, inverse-
    distance blend over the TOP_K nearest bones. Guarantees 100% coverage and
    a real, exportable skin regardless of mesh cleanliness.
    """
    # Armature modifier does the deform; parent just keeps them grouped.
    mod = body.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    body.parent = arm_obj
    body.matrix_parent_inverse = arm_obj.matrix_world.inverted()

    # Bone segments in the same space as body vertices. normalize_orientation()
    # baked Body to an identity matrix (v.co == world) and the Rig sits at the
    # origin, so bone head/tail_local are already in that shared space.
    bones = [(b.name, b.head_local.copy(), b.tail_local.copy())
             for b in arm_obj.data.bones if b.use_deform]

    groups = {}
    for name, _h, _t in bones:
        groups[name] = (body.vertex_groups.get(name)
                        or body.vertex_groups.new(name=name))

    verts = body.data.vertices
    weighted = 0
    for v in verts:
        p = v.co
        # distance to every bone segment
        dists = [((p - _closest_on_segment(p, h, t)).length, name)
                 for name, h, t in bones]
        dists.sort(key=lambda d: d[0])
        chosen = dists[:SKIN_TOP_K]
        ws = [(name, 1.0 / (d ** SKIN_POWER + 1e-6)) for d, name in chosen]
        s = sum(w for _n, w in ws) or 1.0
        for name, w in ws:
            groups[name].add([v.index], w / s, 'REPLACE')
        weighted += 1

    log(f"bind: distance skinning -> {weighted}/{len(verts)} verts weighted "
        f"(power={SKIN_POWER}, top_k={SKIN_TOP_K})")


def animate(arm_obj):
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = 0
    scene.frame_end = FRAME_END

    animated = set()
    for pose in POSES.values():
        animated.update(pose.keys())

    for frame, pose in POSES.items():
        for bone_name in animated:
            pb = arm_obj.pose.bones.get(bone_name)
            if pb is None:
                continue
            pb.rotation_mode = 'XYZ'
            pb.rotation_euler = Euler(pose.get(bone_name, (0.0, 0.0, 0.0)))
            pb.keyframe_insert("rotation_euler", frame=frame)
    scene.frame_set(0)


def export():
    os.makedirs(OUT_DIR, exist_ok=True)
    glb_path = os.path.join(OUT_DIR, f"{EXERCISE}.glb")
    blend_path = os.path.join(OUT_DIR, f"{EXERCISE}.blend")
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        export_animations=True,
        export_yup=True,
    )
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    return glb_path, blend_path


def write_log_file():
    try:
        os.makedirs(OUT_DIR, exist_ok=True)
        with open(os.path.join(OUT_DIR, f"{EXERCISE}_log.txt"), "w") as f:
            f.write("\n".join(_LOG) + "\n")
    except Exception:
        pass


def main():
    clear_scene()
    meshes = import_obj(APP_OBJ)
    body = join_into_body(meshes)
    lo, hi = normalize_orientation(body)
    log(f"model bounds (Blender): {tuple(round(v, 3) for v in lo)} .. "
        f"{tuple(round(v, 3) for v in hi)}  height={hi.z - lo.z:.3f}")
    arm_obj = build_armature(lo, hi)
    bind(body, arm_obj)
    animate(arm_obj)
    glb_path, blend_path = export()

    log(f"[{EXERCISE}] built + exported.")
    log(f"animated model : {glb_path}")
    log(f"editable scene : {blend_path}")
    log(f"frames         : 0..{FRAME_END} @ {FPS}fps "
        f"({FRAME_END / FPS:.1f}s loop)")
    log("tune FACING sign + POSES angles if the stretch looks off.")
    log("next: convert .glb -> .usdz for SceneKit/RealityKit.")


try:
    main()
    write_log_file()
    show_popup("Stretch exported ✓", 'CHECKMARK')
except BaseException as exc:                     # surface errors in the UI too
    log("")
    log(f"ERROR: {exc}")
    log(traceback.format_exc())
    write_log_file()
    show_popup("Script FAILED - see details", 'ERROR')
    raise
