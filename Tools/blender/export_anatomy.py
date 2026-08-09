"""Export the single Body-Map anatomy model from the merged Z-Anatomy blend.

Run: /Applications/Blender.app/Contents/MacOS/Blender -b \
     /Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend \
     --python Tools/blender/export_anatomy.py [-- <decimate_ratio>]

Selects by the three whitelisted collections (NOT by visibility, since the blend
is the full atlas), tags four object classes, and bakes the SAME whole-body
normalization the hitboxes use so mesh and boxes align. Outputs to
Tools/blender/generated/ (Plan 1 staging — Plan 2 moves these into Resources).
"""
import bpy, json, os, re, sys
from mathutils import Vector

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)
from muscle_classification import (
    NON_ANATOMICAL, classify_group, classify_head, classify_face_zone,
    classify_joint, apply_recentre_correction,
)

OUT_DIR = os.path.join(SCRIPT_DIR, "generated")
OBJ_PATH = os.path.join(OUT_DIR, "BodyAnatomy.obj")
MAP_PATH = os.path.join(OUT_DIR, "anatomy_node_names.json")

# (collection name, layer kind). Order = OBJ group order.
COLLECTIONS = [
    ("4: Muscular system", "muscle"),
    ("3: Joints", "joint"),
    ("Regions of head", "headSkin"),
]

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


# --- Whole-body normalization over ALL non-.g meshes (mirror extract_hitboxes) --
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


def classify_object(name: str, kind: str):
    """Tags dict for a kept object, or None to drop it."""
    if kind == "headSkin":
        return {"layer": "headSkin"}
    if kind == "joint":
        region = classify_joint(name)
        return {"layer": "joint", "joint": region} if region else None
    # muscle
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


# --- Select from the whitelisted collections --------------------------------
selected = []          # (obj, node_name, tags)
used_names = set()
for coll_name, kind in COLLECTIONS:
    coll = bpy.data.collections.get(coll_name)
    if coll is None:
        raise SystemExit(f"Collection not found: {coll_name!r}")
    for obj in coll.all_objects:
        if obj.type != 'MESH' or NON_ANATOMICAL.search(obj.name):
            continue
        tags = classify_object(obj.name, kind)
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

print(f"Selected {len(selected)} objects across {len(COLLECTIONS)} collections; writing renderable ones…")

# --- Write the OBJ (baked normalized coords, one `o` group per object) -------
os.makedirs(OUT_DIR, exist_ok=True)
depsgraph = bpy.context.evaluated_depsgraph_get()
lines = [
    "# BodyAnatomy.obj — merged Z-Anatomy muscles + joints + head skin.",
    "# CC-BY-SA 4.0 (Z-Anatomy) / CC-BY-SA 2.1 Japan (BodyParts3D).",
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
    flip = mw.to_3x3().determinant() < 0
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
