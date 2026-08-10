"""Shared muscle-body + skin-head exercise-animation pipeline.

Factored out of clasped_hands_behind_back_muscleonly.py (the first exercise,
see ANIMATION_HANDOFF.md) once a second and third exercise needed the same
plumbing. Per-exercise scripts import this module and supply only:
EXERCISE, VIDEO_NAME, CAMERA_AZIMUTH, WORKED_KEYWORDS, POSES — then call
`run(globals())`.

Still usable paste-in: a per-exercise script computes REPO from its own
__file__ (or a hard-coded path when pasted with no __file__) and inserts the
exercises/ dir onto sys.path before importing this module, so the whole
pipeline works both headless and pasted into Blender's Scripting tab.
"""
import bpy
import bmesh
import math
import os
import traceback
import json
from mathutils import Vector, Euler, Matrix

r = math.radians

# --- On-screen logging (double-clicked Blender has no visible console) -------
_LOG = []


def log(msg):
    _LOG.append(str(msg))
    print(msg)


def show_popup(title, icon):
    # bpy.app.background (headless -b runs) has no window manager to draw a
    # popup into — popup_menu segfaults there instead of raising, so the log
    # file / stdout are the only feedback channel in that mode.
    if bpy.app.background:
        return
    def draw(self, _ctx):
        for line in _LOG:
            for chunk in (line.splitlines() or [""]):
                self.layout.label(text=chunk)
    try:
        bpy.context.window_manager.popup_menu(draw, title=title, icon=icon)
    except Exception:
        pass


FPS = 30
FRAME_END = 120

# Viewport-display / base colours (workbench renders read diffuse_color).
COL_NEUTRAL = (0.62, 0.52, 0.50, 1.0)   # desaturated muscle
COL_HIGHLIGHT = (0.94, 0.42, 0.16, 1.0)  # warm orange
COL_SKIN = (0.87, 0.74, 0.64, 1.0)      # app skinTone

# Joint-blend weighting: each muscle vertex is weighted over the muscle's
# primary bone + that bone's parent/children (its joint-adjacent set) by inverse
# distance. BLEND_POWER high -> mid-muscle verts stay ~rigid, only verts near a
# joint blend, so joint-spanning muscles stretch instead of detaching.
BLEND_POWER = 4.0
BLEND_TOP_K = 2

# --- Landmarks as a fraction of total height (0 = feet, 1 = head) ------------
FR = {
    "feet": 0.02, "knee": 0.28, "hip": 0.50, "spine_top": 0.68,
    "chest_top": 0.80, "shoulder": 0.80, "neck": 0.84, "head_top": 1.00,
    "elbow": 0.615, "wrist": 0.44,
}
SHOULDER_X = 0.12
HIP_X = 0.055


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
    if hasattr(bpy.ops.wm, "obj_import"):
        bpy.ops.wm.obj_import(filepath=path)
    else:
        bpy.ops.import_scene.obj(filepath=path)
    new = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    if not new:
        raise SystemExit("Import produced no mesh objects.")
    return new


def load_node_map(node_map_path):
    with open(node_map_path) as f:
        return json.load(f)["nodes"]


def group_to_bone(group):
    """Data-driven muscle-group -> bone. Mirrors the handoff table; side comes
    from the Left/Right prefix. Returns None if no keyword matches."""
    g = group.lower()
    side = ".L" if g.startswith("left") else (".R" if g.startswith("right") else "")
    rules = [
        (("bicep", "tricep", "shoulder", "deltoid"), "upperarm" + side),
        (("forearm", "hand", "wrist"),               "forearm" + side),
        (("chest", "lat", "trapez", "pec"),          "chest"),
        (("oblique", "abs", "abdom", "erector", "lower back", "spinal"), "spine"),
        (("glute", "hip", "adductor", "groin"),      "hips"),
        (("quad", "hamstring", "thigh"),             "thigh" + side),
        (("calf", "calves", "tibialis", "shin", "foot"), "shin" + side),
        (("neck", "head"),                           "head"),
    ]
    for kws, bone in rules:
        if any(k in g for k in kws):
            return bone
    return None


def world_bounds_of(objs):
    cs = []
    for o in objs:
        cs += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs)))
    hi = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))
    return lo, hi


def normalize_orientation(objs):
    """Rotate ALL objects by one shared transform so the tallest axis -> Z and
    the widest remaining -> X, then drop to the floor and centre horizontally.
    Applied uniformly so the pieces stay aligned to each other."""
    lo, hi = world_bounds_of(objs)
    ext = hi - lo
    axes = sorted(range(3), key=lambda i: ext[i], reverse=True)
    up = axes[0]
    horiz = sorted(axes[1:], key=lambda i: ext[i], reverse=True)
    lr, depth = horiz[0], horiz[1]
    src = [lr, depth, up]
    R = Matrix.Identity(3)
    for dst_axis, s in enumerate(src):
        row = [0.0, 0.0, 0.0]
        row[s] = 1.0
        R[dst_axis] = row
    R4 = R.to_4x4()
    for o in objs:
        o.matrix_world = R4 @ o.matrix_world
    _apply_transforms(objs, rotation=True)

    lo, hi = world_bounds_of(objs)
    offset = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    for o in objs:
        o.matrix_world = Matrix.Translation(-offset) @ o.matrix_world
    _apply_transforms(objs, location=True)
    return world_bounds_of(objs)


def _apply_transforms(objs, location=False, rotation=False, scale=False):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.transform_apply(location=location, rotation=rotation, scale=scale)


def detect_neck_z(skin, lo, hi):
    """Neck = the narrowest horizontal cross-section of the skin in the band
    just below the head. Scan Z slabs in [0.72,0.93] of height, width = X-extent
    of skin verts in the slab, take the Z of the global minimum width."""
    h = hi.z - lo.z
    z0 = lo.z
    band_lo, band_hi = z0 + 0.72 * h, z0 + 0.93 * h
    n_slabs = 40
    slab_h = (band_hi - band_lo) / n_slabs
    xs_by_slab = [[] for _ in range(n_slabs)]
    for v in skin.data.vertices:
        wz = (skin.matrix_world @ v.co).z
        if band_lo <= wz < band_hi:
            i = min(n_slabs - 1, int((wz - band_lo) / slab_h))
            xs_by_slab[i].append((skin.matrix_world @ v.co).x)
    best_z, best_w = z0 + 0.80 * h, 1e9   # fallback: fixed 0.80
    for i, xs in enumerate(xs_by_slab):
        if len(xs) < 8:
            continue
        w = max(xs) - min(xs)
        if w < best_w:
            best_w, best_z = w, band_lo + (i + 0.5) * slab_h
    return best_z, best_w


def clip_skin_to_head(skin, neck_z):
    """Delete skin geometry below neck_z, leaving a head cap."""
    before = len(skin.data.vertices)
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    mw = skin.matrix_world
    doomed = [v for v in bm.verts if (mw @ v.co).z < neck_z]
    bmesh.ops.delete(bm, geom=doomed, context='VERTS')
    bm.to_mesh(skin.data)
    bm.free()
    skin.data.update()
    log(f"skin clip: {before} -> {len(skin.data.vertices)} verts kept (head cap)")


def build_armature(lo, hi):
    h = hi.z - lo.z
    z0 = lo.z

    def z(frac):
        return z0 + frac * h

    xs = SHOULDER_X * h
    xh = HIP_X * h
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
    bone_segs = [(b.name, b.head_local.copy(), b.tail_local.copy())
                 for b in arm_obj.data.bones if b.use_deform]
    return arm_obj, bone_segs


def _closest_on_segment(p, a, b):
    ab = b - a
    denom = ab.length_squared
    if denom < 1e-12:
        return a.copy()
    t = max(0.0, min(1.0, (p - a).dot(ab) / denom))
    return a + ab * t


def nearest_bone(centroid, bone_segs):
    return min(bone_segs,
              key=lambda seg: (centroid - _closest_on_segment(centroid, seg[1], seg[2])).length)[0]


def make_material(name, rgba):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 0.6
    m.diffuse_color = rgba   # workbench viewport render reads this
    return m


def convex_hull_object(obj):
    """Replace obj's geometry with its convex hull — collapses the many thin
    finger/tendon meshes of the anatomy hand into one solid 'mitt' that can't
    splay into strands when the forearm rotates."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    res = bmesh.ops.convex_hull(bm, input=bm.verts)
    junk = set(res.get('geom_unused', [])) | set(res.get('geom_interior', []))
    if junk:
        bmesh.ops.delete(bm, geom=list(junk), context='VERTS')
    if bm.faces:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def add_armature(obj, arm_obj):
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    obj.parent = arm_obj
    obj.matrix_parent_inverse = arm_obj.matrix_world.inverted()


def build_figure(meshes, arm_obj, bone_segs, node_map, worked_keywords):
    mat_neutral = make_material("MuscleNeutral", COL_NEUTRAL)
    mat_highlight = make_material("MuscleWorked", COL_HIGHLIGHT)
    mat_skin = make_material("HeadSkin", COL_SKIN)

    def lookup(name):
        if name in node_map:
            return node_map[name]
        base = name.rsplit(".", 1)[0]   # strip Blender's .001 dedup suffix
        return node_map.get(base)

    # Bone segment lookup + each bone's joint-adjacent set (self+parent+children).
    seg_by_name = {name: (h, t) for name, h, t in bone_segs}
    cand_by_bone = {}
    for b in arm_obj.data.bones:
        if not b.use_deform:
            continue
        names = [b.name]
        if b.parent and b.parent.use_deform:
            names.append(b.parent.name)
        names += [c.name for c in b.children if c.use_deform]
        cand_by_bone[b.name] = names

    skin = None
    muscle_objs = []
    hull_objs = {}   # bone name -> [extremity objects to hull into one mitt]
    counts = {"highlight": 0, "neutral": 0, "mapped": 0, "fallback": 0,
              "blended_verts": 0, "mitts": 0}

    def blend_weights(obj, primary_bone):
        """Per-vertex inverse-distance weight over the bone's joint-adjacent set
        (self+parent+children). Keeps mid-body verts ~rigid to the primary bone,
        blends only near a joint so joint-spanning geometry stretches, not tears."""
        cand = cand_by_bone.get(primary_bone, [primary_bone])
        segs = [(n, seg_by_name[n][0], seg_by_name[n][1]) for n in cand]
        vgs = {n: (obj.vertex_groups.get(n) or obj.vertex_groups.new(name=n)) for n in cand}
        for v in obj.data.vertices:
            p = v.co
            dl = sorted(((p - _closest_on_segment(p, h, t)).length, n) for n, h, t in segs)
            chosen = dl[:BLEND_TOP_K]
            ws = [(n, 1.0 / (d ** BLEND_POWER + 1e-9)) for d, n in chosen]
            s = sum(w for _n, w in ws) or 1.0
            for n, w in ws:
                vgs[n].add([v.index], w / s, 'REPLACE')
            if len(chosen) > 1 and chosen[1][0] < chosen[0][0] * 2.0:
                counts["blended_verts"] += 1

    for o in meshes:
        info = lookup(o.name) or {}
        if info.get("layer") == "skin" or o.name.lower().startswith("bodyskin"):
            skin = o
            continue
        group = info.get("group", "")
        # The lower arms (forearm + hand) and feet are thin splayed tendon meshes
        # in this atlas that strand when posed. Collect them to convex-hull into
        # one solid club each after the loop. Forearm+hand share the forearm bone
        # so they merge into a single seamless lower-arm club.
        gl = group.lower()
        if "hand" in gl or "foot" in gl:
            side = "L" if gl.startswith("left") else "R"
            part = "foot" if "foot" in gl else "hand"
            bone = f"shin.{side}" if part == "foot" else f"forearm.{side}"
            entry = hull_objs.setdefault(f"{part}.{side}", {"bone": bone, "objs": []})
            entry["objs"].append(o)
            continue
        bone = group_to_bone(group) if group else None
        if bone and arm_obj.data.bones.get(bone):
            counts["mapped"] += 1
        else:
            centroid = sum((o.matrix_world @ v.co for v in o.data.vertices),
                           Vector()) / max(1, len(o.data.vertices))
            bone = nearest_bone(centroid, bone_segs)
            counts["fallback"] += 1
        blend_weights(o, bone)
        # material
        worked = any(k in group.lower() for k in worked_keywords)
        o.data.materials.clear()
        o.data.materials.append(mat_highlight if worked else mat_neutral)
        counts["highlight" if worked else "neutral"] += 1
        muscle_objs.append(o)

    # Convex-hull each extremity cluster (hand, foot) into one solid mitt, then
    # joint-blend weight it so its proximal end stays connected across the joint.
    # (Forearms are NOT hulled — their convex hull comes out an ugly flat paddle;
    # they keep their real geometry + joint-blend via the normal muscle path.)
    for key, entry in hull_objs.items():
        bone, objs = entry["bone"], entry["objs"]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        mitt = bpy.context.view_layer.objects.active
        mitt.name = f"Club.{key}"
        convex_hull_object(mitt)
        blend_weights(mitt, bone)
        mitt.data.materials.clear()
        mitt.data.materials.append(mat_neutral)
        muscle_objs.append(mitt)
        counts["neutral"] += 1
        counts["mitts"] += 1

    if skin is None:
        raise SystemExit("No skin object found in the OBJ.")
    return skin, muscle_objs, mat_skin, counts


def join_muscles(muscle_objs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in muscle_objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = muscle_objs[0]
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = "Muscles"
    return body


def bind_head_skin(skin, arm_obj, mat_skin):
    skin.name = "HeadSkin"
    vg = skin.vertex_groups.new(name="head")
    vg.add(list(range(len(skin.data.vertices))), 1.0, 'REPLACE')
    skin.data.materials.clear()
    skin.data.materials.append(mat_skin)
    add_armature(skin, arm_obj)


def animate(arm_obj, poses, frame_end=FRAME_END, fps=FPS):
    scene = bpy.context.scene
    scene.render.fps = fps
    scene.frame_start = 0
    scene.frame_end = frame_end
    animated = set()
    for pose in poses.values():
        animated.update(pose.keys())
    for frame, pose in poses.items():
        for bone_name in animated:
            pb = arm_obj.pose.bones.get(bone_name)
            if pb is None:
                continue
            pb.rotation_mode = 'XYZ'
            pb.rotation_euler = Euler(pose.get(bone_name, (0.0, 0.0, 0.0)))
            pb.keyframe_insert("rotation_euler", frame=frame)
    scene.frame_set(0)


def setup_render(lo, hi, ortho_scale_mult=1.15):
    """`ortho_scale_mult` widens the fixed camera framing beyond the rest-pose
    bounding box — needed for poses (e.g. a forward fold) whose peak silhouette
    extends well outside the standing-rest bounds on the depth axis, since one
    static camera must frame the whole rest->peak->rest loop."""
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.render.resolution_x = 720
    scene.render.resolution_y = 1280
    scene.render.film_transparent = True
    shading = scene.display.shading
    shading.light = 'STUDIO'
    shading.color_type = 'MATERIAL'
    shading.show_shadows = False
    cz = (lo.z + hi.z) / 2
    h = hi.z - lo.z
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = h * ortho_scale_mult
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    return cam, cz


def camera_for_azimuth(az_deg, cz, radius=6.0):
    """Camera location + rotation for an azimuth around the standing figure.
    0 = front, 90 = right side, 180 = back. Level (horizontal) framing."""
    th = r(az_deg)
    loc = (radius * math.sin(th), -radius * math.cos(th), cz)
    rot = (r(90), 0, th)
    return loc, rot


def render_view(cam, cz, out_dir, exercise, name, loc, rot):
    cam.location = Vector(loc)
    cam.rotation_euler = Euler(rot)
    bpy.context.view_layer.update()
    path = os.path.join(out_dir, f"{exercise}_{name}.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    log(f"render: {name} -> {path}")
    return path


def render_all(cam, cz, out_dir, exercise, camera_azimuth, peak_frame=60):
    scene = bpy.context.scene
    demo_loc, demo_rot = camera_for_azimuth(camera_azimuth, cz)
    front_loc, front_rot = camera_for_azimuth(0, cz)
    scene.frame_set(0)
    render_view(cam, cz, out_dir, exercise, "rest_demo", demo_loc, demo_rot)
    scene.frame_set(peak_frame)
    render_view(cam, cz, out_dir, exercise, "peak_demo", demo_loc, demo_rot)
    render_view(cam, cz, out_dir, exercise, "peak_front", front_loc, front_rot)
    scene.frame_set(0)


def render_demo_video(cam, cz, out_dir, exercise, video_name, camera_azimuth,
                       frame_end=FRAME_END, fps=FPS):
    """Render the loop from the demo angle to an opaque PNG sequence — the clip
    the app plays. This Blender build has no FFMPEG encoder, so an external
    AVFoundation step (encode_mp4.swift) turns these frames into the .mp4.
    Frames 0..frame_end-1 (frame_end excluded — it equals frame 0) so the video
    loops seamlessly. Opaque dark 'media panel' background, portrait 4:5 framing."""
    scene = bpy.context.scene
    scene.render.film_transparent = False
    sh = scene.display.shading
    sh.background_type = 'VIEWPORT'
    sh.background_color = (0.05, 0.08, 0.10)   # app dark surface
    scene.render.resolution_x = 512
    scene.render.resolution_y = 640            # portrait 4:5
    scene.render.fps = fps
    scene.frame_start = 0
    scene.frame_end = frame_end - 1
    loc, rot = camera_for_azimuth(camera_azimuth, cz)
    cam.location = Vector(loc)
    cam.rotation_euler = Euler(rot)
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'
    demo_frames_dir = os.path.join(out_dir, f"_demo_frames_{exercise}")
    os.makedirs(demo_frames_dir, exist_ok=True)
    for f in os.listdir(demo_frames_dir):
        if f.endswith(".png"):
            os.remove(os.path.join(demo_frames_dir, f))
    scene.render.filepath = os.path.join(demo_frames_dir, "frame_")
    bpy.ops.render.render(animation=True)
    log(f"demo frames -> {demo_frames_dir} (encode to {video_name} next)")
    return demo_frames_dir


def export(out_dir, exercise):
    os.makedirs(out_dir, exist_ok=True)
    glb_path = os.path.join(out_dir, f"{exercise}.glb")
    blend_path = os.path.join(out_dir, f"{exercise}.blend")
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        export_animations=True,
        export_yup=True,
    )
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    return glb_path, blend_path


def write_log_file(out_dir, exercise):
    try:
        os.makedirs(out_dir, exist_ok=True)
        with open(os.path.join(out_dir, f"{exercise}_log.txt"), "w") as f:
            f.write("\n".join(_LOG) + "\n")
    except Exception:
        pass


def camera_topdown(center, height_above, span, ortho_scale_mult=1.15):
    """Camera for a supine (lying) figure: positioned directly above the
    posed figure's center, looking straight down. A bare Blender camera's
    un-rotated view direction is already -Z (top-down) — this is *why*
    camera_for_azimuth needs rot=(90,0,th) to reach its normal level shots —
    so rotation stays (0,0,0) here. See ANIMATION_HANDOFF.md's "Supine pose
    probe" section for the derivation and the render that validated it:
    head at the top of the portrait frame, feet at the bottom, matching the
    app's 4:5 clip aspect."""
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = span * ortho_scale_mult
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    cam.location = Vector((center.x, center.y, height_above))
    cam.rotation_euler = Euler((0, 0, 0))
    return cam


def apply_supine_base(arm_obj, roll_deg=0):
    """Tips the whole rig from standing to lying flat, face-up, then
    optionally rolls it onto its side around the now-horizontal length axis.

    hips local-X = -90 (pose-bone rotation) tips the ENTIRE chain — every
    other bone is a descendant of hips — from standing to lying flat,
    face-up. Proven numerically + visually 2026-08-09 (see
    ANIMATION_HANDOFF.md). This must also be included as a constant "hips":
    (r(-90), 0, 0) entry in every frame of the script's own POSES dict (this
    function only sets rest-frame defaults for bounds/camera setup before
    `animate()` runs and overwrites it per keyframe).

    roll_deg additionally rotates the ARMATURE OBJECT ITSELF (not another
    pose-bone rotation) around world Y, the axis the body now lies along.
    This is deliberately an object-level transform, not a second hips
    pose-bone Euler component: stacking a second pose-bone rotation on an
    already-pitched bone does NOT roll it onto its side (tried, and the body
    just re-spins in the horizontal plane while staying face-up — composing
    Euler angles in a bone's own already-rotated local frame is not
    equivalent to a world-space roll). Object-level rotation composes in
    true world space, applied after the internal pose, and does roll the
    body around its own length axis correctly. +90 puts the RIGHT side up
    (lying on the LEFT side); -90 puts the LEFT side up (lying on the RIGHT
    side) — verified by bone-tail Z comparison, not assumed from the sign.
    """
    hb = arm_obj.pose.bones.get("hips")
    hb.rotation_mode = 'XYZ'
    hb.rotation_euler = Euler((r(-90), 0, 0))
    arm_obj.rotation_mode = 'XYZ'
    arm_obj.rotation_euler = Euler((0, r(roll_deg), 0))


def render_all_supine(cam, out_dir, exercise, peak_frame=60):
    scene = bpy.context.scene
    scene.frame_set(0)
    render_view(cam, None, out_dir, exercise, "rest_demo", cam.location, cam.rotation_euler)
    scene.frame_set(peak_frame)
    render_view(cam, None, out_dir, exercise, "peak_demo", cam.location, cam.rotation_euler)
    scene.frame_set(0)


def render_demo_video_supine(cam, out_dir, exercise, video_name, frame_end=FRAME_END, fps=FPS):
    """Same as render_demo_video but reuses whatever camera/location the
    caller already positioned (a top-down supine shot) instead of deriving
    one from camera_for_azimuth, which assumes an orbiting-around-a-standing-
    figure camera that doesn't apply once the figure is lying down."""
    scene = bpy.context.scene
    scene.render.film_transparent = False
    sh = scene.display.shading
    sh.background_type = 'VIEWPORT'
    sh.background_color = (0.05, 0.08, 0.10)
    scene.render.resolution_x = 512
    scene.render.resolution_y = 640
    scene.render.fps = fps
    scene.frame_start = 0
    scene.frame_end = frame_end - 1
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'
    demo_frames_dir = os.path.join(out_dir, f"_demo_frames_{exercise}")
    os.makedirs(demo_frames_dir, exist_ok=True)
    for f in os.listdir(demo_frames_dir):
        if f.endswith(".png"):
            os.remove(os.path.join(demo_frames_dir, f))
    scene.render.filepath = os.path.join(demo_frames_dir, "frame_")
    bpy.ops.render.render(animation=True)
    log(f"demo frames -> {demo_frames_dir} (encode to {video_name} next)")
    return demo_frames_dir


def run_supine(cfg):
    """Like `run()`, but for exercises built on the supine base pose
    (apply_supine_base): the standing rest bounds are useless for camera
    sizing once the figure is lying down, so this recomputes bounds from the
    POSED mesh and uses a fixed top-down camera instead of the azimuth-orbit
    camera. cfg needs everything `run()` needs, plus `ROLL_DEG` (0 = flat on
    the back; see apply_supine_base's docstring for signs)."""
    exercise = cfg["EXERCISE"]
    out_dir = cfg["OUT_DIR"]

    def main():
        clear_scene()
        node_map = load_node_map(cfg["NODE_MAP"])
        meshes = import_obj(cfg["APP_OBJ"])
        lo, hi = normalize_orientation(meshes)
        arm_obj, bone_segs = build_armature(lo, hi)
        skin, muscle_objs, mat_skin, counts = build_figure(
            meshes, arm_obj, bone_segs, node_map, cfg["WORKED_KEYWORDS"])
        log(f"muscles: {len(muscle_objs)}  (mapped={counts['mapped']} "
            f"fallback={counts['fallback']}  highlight={counts['highlight']} "
            f"neutral={counts['neutral']}  mitts={counts['mitts']})")

        neck_z, neck_w = detect_neck_z(skin, lo, hi)
        clip_skin_to_head(skin, neck_z)

        muscles = join_muscles(muscle_objs)
        add_armature(muscles, arm_obj)
        bind_head_skin(skin, arm_obj, mat_skin)

        apply_supine_base(arm_obj, cfg.get("ROLL_DEG", 0))
        bpy.context.view_layer.update()

        animate(arm_obj, cfg["POSES"])
        peak_frame = cfg.get("PEAK_FRAME", 60)
        bpy.context.scene.frame_set(peak_frame)
        bpy.context.view_layer.update()
        for bone_name in cfg["POSES"].get(peak_frame, {}):
            pb = arm_obj.pose.bones.get(bone_name)
            if pb:
                w = arm_obj.matrix_world @ pb.tail
                log(f"peak {bone_name} tail world = ({w.x:.3f}, {w.y:.3f}, {w.z:.3f})")

        # Bounds from the POSED mesh at the peak frame (not the pre-pose
        # standing rest bounds `run()` uses) — the figure's shape and extent
        # changed completely once it's lying down.
        plo, phi = world_bounds_of([muscles, skin])
        log(f"posed bounds: {tuple(round(v, 3) for v in plo)} .. "
            f"{tuple(round(v, 3) for v in phi)}")
        center = Vector(((plo.x + phi.x) / 2, (plo.y + phi.y) / 2, (plo.z + phi.z) / 2))
        span = max(phi.y - plo.y, phi.x - plo.x)
        bpy.context.scene.frame_set(0)

        # setup_render's own camera is standing-figure-sized and unwanted
        # here (would leave an orphan camera baked into the export) — only
        # its render-engine/resolution/shading side effects are needed.
        stray_cam, _cz = setup_render(lo, hi, cfg.get("ORTHO_SCALE_MULT", 1.15))
        bpy.data.objects.remove(stray_cam, do_unlink=True)
        cam = camera_topdown(center, phi.z + 3.0, span, cfg.get("ORTHO_SCALE_MULT", 1.15))
        render_all_supine(cam, out_dir, exercise, peak_frame)
        render_demo_video_supine(cam, out_dir, exercise, cfg["VIDEO_NAME"])
        glb_path, blend_path = export(out_dir, exercise)

        log(f"[{exercise}] built + exported.")
        log(f"animated model : {glb_path}")
        log(f"editable scene : {blend_path}")

    try:
        main()
        write_log_file(out_dir, exercise)
        show_popup(f"{exercise} exported ✓", 'CHECKMARK')
    except BaseException as exc:
        log("")
        log(f"ERROR: {exc}")
        log(traceback.format_exc())
        write_log_file(out_dir, exercise)
        show_popup(f"{exercise} FAILED - see details", 'ERROR')
        raise


def run(cfg):
    """cfg is a dict (pass `globals()` from the per-exercise script) providing:
    REPO, APP_OBJ, NODE_MAP, OUT_DIR, EXERCISE, VIDEO_NAME, CAMERA_AZIMUTH,
    WORKED_KEYWORDS, POSES. Optional: PEAK_FRAME (default 60)."""
    exercise = cfg["EXERCISE"]
    out_dir = cfg["OUT_DIR"]

    def main():
        clear_scene()
        node_map = load_node_map(cfg["NODE_MAP"])
        meshes = import_obj(cfg["APP_OBJ"])
        log(f"imported {len(meshes)} objects")
        lo, hi = normalize_orientation(meshes)
        log(f"model bounds: {tuple(round(v, 3) for v in lo)} .. "
            f"{tuple(round(v, 3) for v in hi)}  height={hi.z - lo.z:.3f}")

        arm_obj, bone_segs = build_armature(lo, hi)
        skin, muscle_objs, mat_skin, counts = build_figure(
            meshes, arm_obj, bone_segs, node_map, cfg["WORKED_KEYWORDS"])
        log(f"muscles: {len(muscle_objs)}  (mapped={counts['mapped']} "
            f"fallback={counts['fallback']}  highlight={counts['highlight']} "
            f"neutral={counts['neutral']}  mitts={counts['mitts']})")

        neck_z, neck_w = detect_neck_z(skin, lo, hi)
        log(f"neck detected at z={neck_z:.3f} (width={neck_w:.3f}); "
            f"frac={ (neck_z - lo.z) / (hi.z - lo.z):.3f}")
        clip_skin_to_head(skin, neck_z)

        muscles = join_muscles(muscle_objs)
        add_armature(muscles, arm_obj)
        bind_head_skin(skin, arm_obj, mat_skin)
        log(f"joined muscles -> '{muscles.name}' "
            f"({len(muscles.data.vertices)} verts, {len(muscles.data.materials)} mat slots, "
            f"{len(muscles.vertex_groups)} vgroups)")

        animate(arm_obj, cfg["POSES"])
        peak_frame = cfg.get("PEAK_FRAME", 60)
        bpy.context.scene.frame_set(peak_frame)
        bpy.context.view_layer.update()
        for bone_name in cfg["POSES"].get(peak_frame, {}):
            pb = arm_obj.pose.bones.get(bone_name)
            if pb:
                w = arm_obj.matrix_world @ pb.tail
                log(f"peak {bone_name} tail world = ({w.x:.3f}, {w.y:.3f}, {w.z:.3f})")
        bpy.context.scene.frame_set(0)

        cam, cz = setup_render(lo, hi, cfg.get("ORTHO_SCALE_MULT", 1.15))
        render_all(cam, cz, out_dir, exercise, cfg["CAMERA_AZIMUTH"], peak_frame)
        render_demo_video(cam, cz, out_dir, exercise, cfg["VIDEO_NAME"], cfg["CAMERA_AZIMUTH"])
        glb_path, blend_path = export(out_dir, exercise)

        log(f"[{exercise}] built + exported.")
        log(f"animated model : {glb_path}")
        log(f"editable scene : {blend_path}")

    try:
        main()
        write_log_file(out_dir, exercise)
        show_popup(f"{exercise} exported ✓", 'CHECKMARK')
    except BaseException as exc:
        log("")
        log(f"ERROR: {exc}")
        log(traceback.format_exc())
        write_log_file(out_dir, exercise)
        show_popup(f"{exercise} FAILED - see details", 'ERROR')
        raise
