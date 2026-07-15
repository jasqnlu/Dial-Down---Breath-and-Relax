"""
Run inside Blender (Scripting tab, or `blender --background file.blend --python extract_hitboxes.py`).

Walks every mesh object in the scene, computes its world-space axis-aligned
bounding box, then remaps it into the SAME coordinate space BodySceneView.swift
uses in the app (Y-up, +Z-forward, recentred + scaled to height 2.0) — so the
numbers you get here line up with what's actually rendered in SceneKit.

Why the remap matters: Blender is Z-up by default. The OBJ export path this
project uses assumes Forward = -Z, Up = Y (Blender's default OBJ axis
settings), which is the standard Blender -> Y-up interchange convention. If
your export uses different axis settings, adjust `blender_to_app` below to
match.

Also replicates BodyMeshLoader.makeTemplateBodyNode's recentring/scaling
(Breath - Relax & Stretch/Views/BodyMap/BodySceneView.swift lines 79-89):
pivot = whole-body bounding-box centre, scale = 2.0 / whole-body height.
Without this, per-part boxes come out in raw Blender units, not the
normalised space the app's camera (fieldOfView 50, distance 2.28) expects.

IMPORTANT — Z-Anatomy scene-organisation objects: the source file contains
mesh-type "helper" objects that are NOT anatomy — category folder anchors
(named e.g. "Muscular system.g", "Joints.g" — anything ending in ".g") and
cross-section slicing planes ("Cross Section X/Y/Z"). These have huge,
synthetic bounding boxes (verified: x reaching -0.75+ when real anatomy
tops out around -0.35/+0.66) that will badly skew the recentre/scale
calculation below if included — confirmed empirically: including them
made every muscle, left AND right, land on the same side of x=0 after
"recentring". They're excluded here at the source.
"""

import bpy
import json
import re
from mathutils import Vector

OUTPUT_PATH = "/tmp/body_part_hitboxes.json"
NON_ANATOMICAL = re.compile(r'\.g$|^Cross Section')


def blender_to_app(v: Vector) -> Vector:
    # Blender (X, Y, Z, Z-up) -> app (X, Z, -Y) i.e. Forward -Z / Up Y.
    return Vector((v.x, v.z, -v.y))


def world_aabb(obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    remapped = [blender_to_app(c) for c in corners]
    xs = [c.x for c in remapped]
    ys = [c.y for c in remapped]
    zs = [c.z for c in remapped]
    return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))


mesh_objects = [o for o in bpy.data.objects
                if o.type == 'MESH' and not NON_ANATOMICAL.search(o.name)]

# Pass 1: whole-body bounds (mirrors BodyMeshLoader's recentre/scale step).
whole_min = Vector((float('inf'),) * 3)
whole_max = Vector((float('-inf'),) * 3)
for obj in mesh_objects:
    lo, hi = world_aabb(obj)
    whole_min = Vector(min(a, b) for a, b in zip(whole_min, lo))
    whole_max = Vector(max(a, b) for a, b in zip(whole_max, hi))

center = (whole_min + whole_max) / 2
height = whole_max.y - whole_min.y  # Y is up post-remap
scale = 2.0 / height if height > 0 else 1.0

# Pass 2: per-part boxes, recentred + scaled into the app's model space.
result = {}
for obj in mesh_objects:
    lo, hi = world_aabb(obj)
    lo_n = (lo - center) * scale
    hi_n = (hi - center) * scale
    result[obj.name] = {
        "min": [lo_n.x, lo_n.y, lo_n.z],
        "max": [hi_n.x, hi_n.y, hi_n.z],
    }

with open(OUTPUT_PATH, "w") as f:
    json.dump(result, f, indent=2)

print(f"Wrote {len(result)} object bounding boxes to {OUTPUT_PATH}")
