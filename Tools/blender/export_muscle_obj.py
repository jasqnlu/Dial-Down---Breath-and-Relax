"""
Export the visual muscle mesh for the Body Map's muscle-layer reveal.

Run inside Blender against the Z-Anatomy source file:

    /Applications/Blender.app/Contents/MacOS/Blender --background \
        /Users/jasonlu/Blender/Z-Anatomy.blend \
        --python Tools/blender/export_muscle_obj.py

What it does
------------
1. Selects EXACTLY the mesh objects that classify_hitboxes.py / classify_head_
   hitboxes.py already match to a MuscleGroup or sub-head (via the shared
   muscle_classification module) — the ~64 objects behind the 40 groups + 24
   heads. Every exported chunk is therefore guaranteed nameable + tappable.
2. Bakes the SAME coordinate normalization the hitboxes use — extract_hitboxes.py's
   blender_to_app axis map + whole-body recentre/scale, then the classify
   scripts' apply_recentre_correction second pass — directly into the exported
   vertices. So the muscle mesh lands in the identical normalized space the
   shipped hitboxes live in, and the app's makeTemplateMuscleNode loads it with
   an IDENTITY transform (it must NOT re-normalize, or it would rescale to the
   muscle-only bbox and misalign).
3. Writes a custom OBJ with one `o <name>` group per source object (NOT
   flattened like BodyMale.obj), so SceneKit creates one addressable child node
   per muscle piece — the per-group highlight + hit-test targets.
4. Emits musclegroup_node_names.json: exported node name -> {group, head}.

Outputs (relative to repo root):
    Breath - Relax & Stretch/Resources/Models3D/BodyMuscle.obj
    Breath - Relax & Stretch/Resources/musclegroup_node_names.json
"""

import bpy
import json
import os
import re
import sys
from mathutils import Vector

# Make the shared classification module importable regardless of Blender's cwd.
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)
from muscle_classification import (
    NON_ANATOMICAL, classify_group, classify_head, apply_recentre_correction,
)

# Repo root = two levels up from Tools/blender/.
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
RES_DIR = os.path.join(REPO_ROOT, "Breath - Relax & Stretch", "Resources")
OBJ_PATH = os.path.join(RES_DIR, "Models3D", "BodyMuscle.obj")
MAP_PATH = os.path.join(RES_DIR, "musclegroup_node_names.json")

# Z-Anatomy muscles ship at ~1.28M faces total — far more than a translucent
# reveal-layer (seen behind faded skin, dollied onto one region) needs. Collapse
# each object to this fraction of its faces to keep the bundled asset small.
# Override from the CLI: `--python export_muscle_obj.py -- 0.1`.
DECIMATE_RATIO = 0.15
if "--" in sys.argv:
    extra = sys.argv[sys.argv.index("--") + 1:]
    if extra:
        DECIMATE_RATIO = float(extra[0])


def blender_to_app(v: Vector) -> Vector:
    # Blender (X, Y, Z, Z-up) -> app (X, Z, -Y) i.e. Forward -Z / Up Y.
    # Identical to extract_hitboxes.py — do not diverge or mesh/hitboxes drift.
    return Vector((v.x, v.z, -v.y))


def world_aabb(obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    remapped = [blender_to_app(c) for c in corners]
    xs = [c.x for c in remapped]
    ys = [c.y for c in remapped]
    zs = [c.z for c in remapped]
    return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))


# --- 1. Whole-body normalization (mirrors extract_hitboxes.py exactly) -------
mesh_objects = [o for o in bpy.data.objects
                if o.type == 'MESH' and not NON_ANATOMICAL.search(o.name)]

whole_min = Vector((float('inf'),) * 3)
whole_max = Vector((float('-inf'),) * 3)
for obj in mesh_objects:
    lo, hi = world_aabb(obj)
    whole_min = Vector(min(a, b) for a, b in zip(whole_min, lo))
    whole_max = Vector(max(a, b) for a, b in zip(whole_max, hi))

extract_center = (whole_min + whole_max) / 2
extract_height = whole_max.y - whole_min.y
extract_scale = 2.0 / extract_height if extract_height > 0 else 1.0

# Reproduce the classify scripts' second (correction) affine pass so the mesh
# lands in the FINAL hitbox space, not just the extract space. Build the same
# per-object AABB dict extract_hitboxes.py writes, then reuse the shared helper.
extracted_boxes = {}
for obj in mesh_objects:
    lo, hi = world_aabb(obj)
    lo_n = (lo - extract_center) * extract_scale
    hi_n = (hi - extract_center) * extract_scale
    extracted_boxes[obj.name] = {"min": [lo_n.x, lo_n.y, lo_n.z],
                                 "max": [hi_n.x, hi_n.y, hi_n.z]}
_corrected, corr_center, corr_scale, _excluded = apply_recentre_correction(extracted_boxes)
corr_center = Vector(corr_center)


def to_app_space(world_v: Vector) -> Vector:
    """A world-space vertex -> final normalized app/hitbox space."""
    n1 = (blender_to_app(world_v) - extract_center) * extract_scale
    return (n1 - corr_center) * corr_scale


# --- 2. Select the classified muscle objects + build the node-name map -------
def sanitize(name: str) -> str:
    # OBJ group tokens must be whitespace-free; keep it SceneKit-safe (letters,
    # digits, underscore). Uniqueness is enforced by the caller.
    s = re.sub(r'[^0-9A-Za-z]+', '_', name).strip('_')
    return s or "muscle"


selected = []            # (obj, node_name, group, head)
node_map = {}            # node_name -> {"group": ..., "head": ... | None} (renderable only)
used_names = set()
group_counts = {}

for obj in mesh_objects:
    group = classify_group(obj.name)
    if not group:
        continue
    head = classify_head(obj.name)
    node_name = sanitize(obj.name)
    # Guarantee uniqueness so each parsed child node maps to exactly one entry.
    if node_name in used_names:
        i = 2
        while f"{node_name}_{i}" in used_names:
            i += 1
        node_name = f"{node_name}_{i}"
    used_names.add(node_name)
    selected.append((obj, node_name, group, head))

print(f"Selected {len(selected)} candidate muscle objects; writing the renderable ones…")

# --- 3. Write the OBJ (one `o` group per object, baked normalized coords) ----
os.makedirs(os.path.dirname(OBJ_PATH), exist_ok=True)
depsgraph = bpy.context.evaluated_depsgraph_get()

lines = [
    "# BodyMuscle.obj — Z-Anatomy muscle subset for the Body Map reveal.",
    "# Source: Z-Anatomy (CC-BY-SA 4.0) / BodyParts3D (CC-BY-SA 2.1 Japan).",
    "# Coords pre-normalized to the app's model space (Y-up, +Z-fwd, height 2,",
    "# whole-body recentred) — load with an IDENTITY transform. Do not re-scale.",
    "# One `o` group per muscle object; parse into one SCNNode each.",
]
v_offset = 0  # running global vertex/normal count (OBJ indices are 1-based)

for obj, node_name, group, head in selected:
    # Temporary Decimate modifier — collapse to DECIMATE_RATIO of the faces so
    # the bundled OBJ stays small. evaluated_get applies it; removed after.
    dec = None
    if DECIMATE_RATIO < 1.0:
        dec = obj.modifiers.new(name="_export_decimate", type='DECIMATE')
        dec.decimate_type = 'COLLAPSE'
        dec.ratio = DECIMATE_RATIO
        depsgraph.update()
    eval_obj = obj.evaluated_get(depsgraph)
    mesh = eval_obj.to_mesh()
    mesh.calc_loop_triangles()

    # Skip objects that decimate to nothing (Z-Anatomy `.j` label anchors and
    # near-degenerate slivers). Keeping them out of BOTH the OBJ and the node
    # map means the map describes exactly the renderable nodes — every mapped
    # name resolves to a real SceneKit node at runtime. (These have no bearing
    # on the hitboxes, which are generated from the shared classification.)
    if not mesh.loop_triangles:
        eval_obj.to_mesh_clear()
        if dec is not None:
            obj.modifiers.remove(dec)
        continue

    # Normal matrix: inverse-transpose of the world 3x3 (handles non-uniform scale).
    nmat = eval_obj.matrix_world.to_3x3().inverted_safe().transposed()
    mw = eval_obj.matrix_world

    node_map[node_name] = {"group": group, "head": head}
    group_counts[group] = group_counts.get(group, 0) + 1

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
        lines.append(f"f {a}//{a} {b}//{b} {c}//{c}")
    v_offset += len(mesh.vertices)
    eval_obj.to_mesh_clear()
    if dec is not None:
        obj.modifiers.remove(dec)

with open(OBJ_PATH, "w") as f:
    f.write("\n".join(lines) + "\n")

print(f"Wrote {v_offset} vertices to {OBJ_PATH}")

# --- 4. Emit the node-name -> group/head map --------------------------------
with open(MAP_PATH, "w") as f:
    json.dump({"nodes": node_map}, f, indent=2, sort_keys=True)
print(f"Wrote {len(node_map)} node mappings to {MAP_PATH}")

# --- Report: coverage per group (a quick sanity glance before the Swift verify)
print("\nPer-group object counts:")
for group in sorted(group_counts):
    print(f"  {group}: {group_counts[group]}")
