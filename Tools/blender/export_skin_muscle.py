"""Export the skin-covered Body-Map model: one welded skin shell + muscle layer.

Run: /Applications/Blender.app/Contents/MacOS/Blender -b \
     /Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend \
     --python Tools/blender/export_skin_muscle.py [-- <decimate_ratio>]

Joins the 296 body-region patches in collection "9: Regions of human body"
into a single watertight `BodySkin` object (bmesh remove_doubles -> holes_fill
-> recalc_face_normals), then bakes the SAME whole-body normalization the
hitboxes and export_anatomy.py use so mesh, boxes, and the skin shell all
align. Muscles come from "4: Muscular system" via
classify_group/classify_head/classify_face_zone. The "3: Joints" collection is
NOT touched — no joint geometry in this export. Outputs to
Tools/blender/generated/ (skin-covered pivot staging).
"""
import bpy, bmesh, json, os, re, sys
from mathutils import Vector

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)
from muscle_classification import (
    NON_ANATOMICAL, classify_group, classify_head, classify_face_zone,
    apply_recentre_correction,
)

OUT_DIR = os.path.join(SCRIPT_DIR, "generated")
OBJ_PATH = os.path.join(OUT_DIR, "BodySkinMuscle.obj")
MAP_PATH = os.path.join(OUT_DIR, "skinmuscle_node_names.json")

SKIN_COLLECTION = "9: Regions of human body"
MUSCLE_COLLECTION = "4: Muscular system"
# Tuned against the real blend: boundary edges bottom out around dist=0.003
# (185 residual, vs. 284 at 0.0008 and 204 at 0.004) once the non-anatomical
# folder anchor + degenerate marker objects below are correctly excluded.
SKIN_WELD_DIST = 0.003

DECIMATE_RATIO = 0.15
if "--" in sys.argv:
    extra = sys.argv[sys.argv.index("--") + 1:]
    if extra:
        DECIMATE_RATIO = float(extra[0])


def blender_to_app(v: Vector) -> Vector:
    return Vector((v.x, v.z, -v.y))


def world_aabb(obj):
    corners = [blender_to_app(obj.matrix_world @ Vector(c)) for c in obj.bound_box]
    xs = [c.x for c in corners]; ys = [c.y for c in corners]; zs = [c.z for c in corners]
    return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))


# --- Skin prep: weld the 296 body-region patches into one BodySkin object --
# Must run BEFORE the whole-body normalization bounds below so BodySkin is
# included in `mesh_objects`.
def find_layer_collection(layer_coll, name):
    if layer_coll.name == name:
        return layer_coll
    for child in layer_coll.children:
        found = find_layer_collection(child, name)
        if found is not None:
            return found
    return None


skin_layer_coll = find_layer_collection(bpy.context.view_layer.layer_collection, SKIN_COLLECTION)
if skin_layer_coll is None:
    raise SystemExit(f"Collection not found: {SKIN_COLLECTION!r}")
skin_layer_coll.exclude = False  # un-exclude so its objects are selectable/joinable

skin_coll = bpy.data.collections.get(SKIN_COLLECTION)
if skin_coll is None:
    raise SystemExit(f"Collection not found: {SKIN_COLLECTION!r}")
# The collection also holds the ".g" category-folder anchor for itself plus a
# handful of 2-vertex/0-face "region" reference markers (Z-Anatomy pin
# objects, not surface geometry) — both must be excluded or they either
# pollute the join (the ".g" anchor's own huge placeholder mesh) or add
# spurious geometry-free objects.
skin_patches = [o for o in skin_coll.all_objects
                if o.type == 'MESH' and not NON_ANATOMICAL.search(o.name)
                and len(o.data.polygons) > 0]
if not skin_patches:
    raise SystemExit(f"No mesh patches found in {SKIN_COLLECTION!r}")

bpy.ops.object.select_all(action='DESELECT')
for o in skin_patches:
    o.select_set(True)
active_patch = skin_patches[0]
bpy.context.view_layer.objects.active = active_patch
# bpy.ops.object.join() silently no-ops in headless (-b) execution without an
# explicit context override — without this, "active" ends up not recognized
# as a selected mesh and the op leaves BodySkin as just the first patch.
with bpy.context.temp_override(active_object=active_patch,
                                selected_objects=skin_patches,
                                selected_editable_objects=skin_patches):
    bpy.ops.object.join()
body_skin = bpy.context.view_layer.objects.active
body_skin.name = "BodySkin"

bm = bmesh.new()
bm.from_mesh(body_skin.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=SKIN_WELD_DIST)
bmesh.ops.holes_fill(bm, edges=bm.edges, sides=0)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(body_skin.data)
bm.free()
body_skin.data.update()

print(f"Welded {len(skin_patches)} skin patches into BodySkin "
      f"({len(body_skin.data.vertices)} verts, {len(body_skin.data.polygons)} faces)")


# --- Whole-body normalization over ALL non-.g meshes (mirror extract_hitboxes) --
# BodySkin is now a real mesh object in the scene, so it's included here.
mesh_objects = [o for o in bpy.data.objects
                if o.type == 'MESH' and not NON_ANATOMICAL.search(o.name)]
whole_min = Vector((float('inf'),) * 3)
whole_max = Vector((float('-inf'),) * 3)
for obj in mesh_objects:
    lo, hi = world_aabb(obj)
    whole_min = Vector(min(a, b) for a, b in zip(whole_min, lo))
    whole_max = Vector(max(a, b) for a, b in zip(whole_max, hi))
extract_center = (whole_min + whole_max) / 2
extract_scale = 2.0 / (whole_max.y - whole_min.y) if whole_max.y > whole_min.y else 1.0

extracted_boxes = {}
for obj in mesh_objects:
    lo, hi = world_aabb(obj)
    lo_n = (lo - extract_center) * extract_scale
    hi_n = (hi - extract_center) * extract_scale
    extracted_boxes[obj.name] = {"min": [lo_n.x, lo_n.y, lo_n.z], "max": [hi_n.x, hi_n.y, hi_n.z]}
_c, corr_center, corr_scale, _n = apply_recentre_correction(extracted_boxes)
corr_center = Vector(corr_center)


def to_app_space(world_v: Vector) -> Vector:
    n1 = (blender_to_app(world_v) - extract_center) * extract_scale
    return (n1 - corr_center) * corr_scale


def sanitize(name: str) -> str:
    s = re.sub(r'[^0-9A-Za-z]+', '_', name).strip('_')
    return s or "node"


def classify_muscle(name: str):
    group = classify_group(name)
    if not group:
        return None
    entry = {"layer": "muscle", "group": group}
    head = classify_head(name)
    if head:
        entry["head"] = head
    zone = classify_face_zone(name)
    if zone:
        entry["faceZone"] = zone
    return entry


# --- Select: BodySkin (single object) + muscles from "4: Muscular system" ---
# Do NOT touch "3: Joints" — no joint geometry in this export.
selected = []          # (obj, node_name, tags)
used_names = set()

skin_node_name = sanitize(body_skin.name)
used_names.add(skin_node_name)
selected.append((body_skin, skin_node_name, {"layer": "skin"}))

muscle_coll = bpy.data.collections.get(MUSCLE_COLLECTION)
if muscle_coll is None:
    raise SystemExit(f"Collection not found: {MUSCLE_COLLECTION!r}")
for obj in muscle_coll.all_objects:
    if obj.type != 'MESH' or NON_ANATOMICAL.search(obj.name):
        continue
    tags = classify_muscle(obj.name)
    if tags is None:
        continue
    node_name = sanitize(obj.name)
    if node_name in used_names:
        i = 2
        while f"{node_name}_{i}" in used_names:
            i += 1
        node_name = f"{node_name}_{i}"
    used_names.add(node_name)
    selected.append((obj, node_name, tags))

print(f"Selected {len(selected)} objects (1 skin + {len(selected) - 1} muscles); writing renderable ones…")

# --- Write the OBJ (baked normalized coords, one `o` group per object) -------
os.makedirs(OUT_DIR, exist_ok=True)
depsgraph = bpy.context.evaluated_depsgraph_get()
lines = [
    "# BodySkinMuscle.obj — merged Z-Anatomy welded skin shell + muscles.",
    "# CC-BY-SA 4.0 (Z-Anatomy) / CC-BY 4.0 (BodyParts3D).",
    "# Pre-normalized to app model space (Y-up,+Z-fwd,height 2) — IDENTITY load.",
]
v_offset = 0
node_map = {}
layer_counts = {}
for obj, node_name, tags in selected:
    dec = None
    if DECIMATE_RATIO < 1.0:
        dec = obj.modifiers.new(name="_export_decimate", type='DECIMATE')
        dec.decimate_type = 'COLLAPSE'
        dec.ratio = DECIMATE_RATIO
        depsgraph.update()
    eval_obj = obj.evaluated_get(depsgraph)
    mesh = eval_obj.to_mesh()
    mesh.calc_loop_triangles()
    if not mesh.loop_triangles:
        eval_obj.to_mesh_clear()
        if dec: obj.modifiers.remove(dec)
        continue
    nmat = eval_obj.matrix_world.to_3x3().inverted_safe().transposed()
    mw = eval_obj.matrix_world
    # Z-Anatomy builds one lateral side as a MIRROR of the other (negative-
    # determinant world matrix). Mirroring reverses triangle winding, so those
    # faces must be re-reversed here — otherwise the double-sided material shades
    # the mirrored half with inverted normals and it renders dark/flat (the
    # "half grey" seam). Flip the face vertex order when the determinant is < 0.
    # BodySkin is excluded: it was joined from many patches and its normals were
    # already made consistent by recalc_face_normals above, so its post-join
    # determinant is not a meaningful per-patch winding signal.
    flip = tags["layer"] != "skin" and mw.to_3x3().determinant() < 0
    node_map[node_name] = tags
    layer_counts[tags["layer"]] = layer_counts.get(tags["layer"], 0) + 1
    lines.append(f"o {node_name}")
    lines.append(f"g {node_name}")
    for v in mesh.vertices:
        p = to_app_space(mw @ v.co)
        lines.append(f"v {p.x:.6f} {p.y:.6f} {p.z:.6f}")
    for v in mesh.vertices:
        n = blender_to_app((nmat @ v.normal)).normalized()
        lines.append(f"vn {n.x:.6f} {n.y:.6f} {n.z:.6f}")
    for tri in mesh.loop_triangles:
        a, b, c = (i + 1 + v_offset for i in tri.vertices)
        if flip:
            lines.append(f"f {a}//{a} {c}//{c} {b}//{b}")
        else:
            lines.append(f"f {a}//{a} {b}//{b} {c}//{c}")
    v_offset += len(mesh.vertices)
    eval_obj.to_mesh_clear()
    if dec: obj.modifiers.remove(dec)

with open(OBJ_PATH, "w") as f:
    f.write("\n".join(lines) + "\n")
with open(MAP_PATH, "w") as f:
    json.dump({"nodes": node_map}, f, indent=2, sort_keys=True)

print(f"Wrote {v_offset} vertices, {len(node_map)} nodes to {OBJ_PATH}")
print(f"Layer counts: {layer_counts}")
