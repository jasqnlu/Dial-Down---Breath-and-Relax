"""Prototype exercise animation: "Clasped Hands Behind Back" stretch.

PASTE-IN SCRIPT — run in Blender's *Scripting* tab (not headless), in a fresh
or expendable .blend, because it CLEARS THE CURRENT SCENE.

What it does (the whole real pipeline, minus weight-painting):
  1. Wipes the scene.
  2. Builds a ~12-bone humanoid ARMATURE (hips, spine, chest, head, L/R
     upper-arm + forearm, L/R thigh + shin) in a standing, arms-down pose.
  3. Builds one colored box per bone and rigidly skins each box to its bone
     (vertex group weight 1.0 + a single Armature modifier). Rigid weighting
     sidesteps weight-painting yet the exported animation data is identical to
     what a real skinned avatar produces.
  4. Keyframes the "clasped hands behind back" stretch as a seamless loop:
        f0   neutral (arms down)
        f30  arms swing behind the back, hands clasp low
        f60  arms straighten + lift away from back, chest opens (peak)
        f90  hold peak
        f120 ease back to neutral -> loops
  5. Exports:
        <OUT_DIR>/clasped_hands_behind_back.glb    <- the animated model
        <OUT_DIR>/clasped_hands_behind_back.blend  <- the editable scene
     and prints the absolute paths + frame range to the console.

NEXT STEP for the app (not done here): convert the .glb to .usdz for
SceneKit/RealityKit, e.g. Apple's Reality Converter, or:
    xcrun usdconvert clasped_hands_behind_back.glb clasped_hands_behind_back.usdz
(the pose rotations below are first-pass and meant to be TUNED in Blender —
positive/negative on an axis may need flipping once you see it move).
"""
import bpy
import math
import os
from mathutils import Vector, Euler

r = math.radians

# --- Where the exported files land. Edit this if your repo is elsewhere. -----
OUT_DIR = ("/Users/jasonlu/Desktop/X-Code Projects/Breath - Relax & Stretch"
           "/Tools/blender/generated/exercises")
EXERCISE = "clasped_hands_behind_back"

FPS = 30
FRAME_END = 120

# --- Skeleton: (name, head, tail, parent). Blender is Z-up; figure faces -Y. -
# All bones are vertical here, which keeps the boxes axis-aligned (no rotation
# math needed to build them) — the arms hang straight down in the rest pose.
BONES = [
    ("hips",       (0.00, 0.0, 1.00), (0.00, 0.0, 1.12), None),
    ("spine",      (0.00, 0.0, 1.12), (0.00, 0.0, 1.38), "hips"),
    ("chest",      (0.00, 0.0, 1.38), (0.00, 0.0, 1.55), "spine"),
    ("head",       (0.00, 0.0, 1.57), (0.00, 0.0, 1.78), "chest"),
    ("upperarm.L", (0.17, 0.0, 1.52), (0.17, 0.0, 1.20), "chest"),
    ("forearm.L",  (0.17, 0.0, 1.20), (0.17, 0.0, 0.92), "upperarm.L"),
    ("upperarm.R", (-0.17, 0.0, 1.52), (-0.17, 0.0, 1.20), "chest"),
    ("forearm.R",  (-0.17, 0.0, 1.20), (-0.17, 0.0, 0.92), "upperarm.R"),
    ("thigh.L",    (0.10, 0.0, 1.00), (0.10, 0.0, 0.55), "hips"),
    ("shin.L",     (0.10, 0.0, 0.55), (0.10, 0.0, 0.08), "thigh.L"),
    ("thigh.R",    (-0.10, 0.0, 1.00), (-0.10, 0.0, 0.55), "hips"),
    ("shin.R",     (-0.10, 0.0, 0.55), (-0.10, 0.0, 0.08), "thigh.R"),
]

# Per-bone box half-thickness (X/Y) and a colour key for grouping.
TORSO = {"thick": 0.11, "color": (0.85, 0.70, 0.60, 1.0)}
LIMB_ARM = {"thick": 0.055, "color": (0.30, 0.55, 0.85, 1.0)}
LIMB_LEG = {"thick": 0.075, "color": (0.35, 0.60, 0.40, 1.0)}
STYLE = {
    "hips": TORSO, "spine": TORSO, "chest": TORSO, "head": TORSO,
    "upperarm.L": LIMB_ARM, "forearm.L": LIMB_ARM,
    "upperarm.R": LIMB_ARM, "forearm.R": LIMB_ARM,
    "thigh.L": LIMB_LEG, "shin.L": LIMB_LEG,
    "thigh.R": LIMB_LEG, "shin.R": LIMB_LEG,
}

# --- The stretch, as per-frame bone euler rotations (radians). ---------------
# Any bone omitted at a keyframe is driven back to (0,0,0), which is why f0 and
# f120 (empty) return the figure to a clean neutral for a seamless loop.
POSES = {
    0: {},
    30: {  # arms swing behind the back, hands meet low (clasp)
        "upperarm.L": (r(-35), 0, r(-15)),
        "upperarm.R": (r(-35), 0, r(15)),
        "forearm.L":  (r(-70), 0, r(-25)),
        "forearm.R":  (r(-70), 0, r(25)),
        "chest":      (r(5), 0, 0),
    },
    60: {  # straighten + lift clasped hands, chest opens (peak stretch)
        "upperarm.L": (r(-55), 0, r(-8)),
        "upperarm.R": (r(-55), 0, r(8)),
        "forearm.L":  (r(-20), 0, r(-10)),
        "forearm.R":  (r(-20), 0, r(10)),
        "chest":      (r(-12), 0, 0),
        "head":       (r(-8), 0, 0),
    },
    90: {  # hold the peak
        "upperarm.L": (r(-55), 0, r(-8)),
        "upperarm.R": (r(-55), 0, r(8)),
        "forearm.L":  (r(-20), 0, r(-10)),
        "forearm.R":  (r(-20), 0, r(10)),
        "chest":      (r(-12), 0, 0),
        "head":       (r(-8), 0, 0),
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
    # Drop leftover datablocks so re-runs don't pile up ".001" names.
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials):
        for block in list(coll):
            if block.users == 0:
                coll.remove(block)


def make_material(name, rgba):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:                       # carries colour into the .glb
        bsdf.inputs["Base Color"].default_value = rgba
    mat.diffuse_color = rgba                    # viewport colour
    return mat


def build_armature():
    arm_data = bpy.data.armatures.new("Rig")
    arm_obj = bpy.data.objects.new("Rig", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = {}
    for name, head, tail, _parent in BONES:
        eb = arm_data.edit_bones.new(name)
        eb.head = Vector(head)
        eb.tail = Vector(tail)
        edit_bones[name] = eb
    for name, _h, _t, parent in BONES:
        if parent:
            edit_bones[name].parent = edit_bones[parent]  # not connected: arm
    bpy.ops.object.mode_set(mode='OBJECT')                 # heads aren't shared
    return arm_obj


def build_segment_box(name, head, tail):
    """One axis-aligned box spanning head->tail, fully weighted to `name`."""
    style = STYLE[name]
    mid = (Vector(head) + Vector(tail)) / 2.0
    length = (Vector(tail) - Vector(head)).length
    t = style["thick"]

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=mid)
    box = bpy.context.active_object
    box.name = f"seg_{name}"
    box.scale = (t, t, max(length, 0.02))
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    vg = box.vertex_groups.new(name=name)                  # rigid skin: w=1.0
    vg.add(range(len(box.data.vertices)), 1.0, 'REPLACE')

    box.data.materials.append(make_material(f"mat_{name}", style["color"]))
    return box


def build_figure(arm_obj):
    boxes = [build_segment_box(name, head, tail)
             for name, head, tail, _p in BONES]

    bpy.ops.object.select_all(action='DESELECT')
    for b in boxes:
        b.select_set(True)
    bpy.context.view_layer.objects.active = boxes[0]
    bpy.ops.object.join()                                  # keeps vertex groups
    figure = bpy.context.view_layer.objects.active
    figure.name = "Figure"

    mod = figure.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    figure.parent = arm_obj
    return figure


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
            pb = arm_obj.pose.bones[bone_name]
            pb.rotation_mode = 'XYZ'
            pb.rotation_euler = Euler(pose.get(bone_name, (0.0, 0.0, 0.0)))
            pb.keyframe_insert("rotation_euler", frame=frame)

    scene.frame_set(0)


def export(figure):
    os.makedirs(OUT_DIR, exist_ok=True)
    glb_path = os.path.join(OUT_DIR, f"{EXERCISE}.glb")
    blend_path = os.path.join(OUT_DIR, f"{EXERCISE}.blend")

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        export_animations=True,
        export_yup=True,          # Z-up (Blender) -> Y-up (glTF/SceneKit)
    )
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    return glb_path, blend_path


def main():
    clear_scene()
    arm_obj = build_armature()
    figure = build_figure(arm_obj)
    animate(arm_obj)
    glb_path, blend_path = export(figure)

    print("\n" + "=" * 60)
    print(f"[{EXERCISE}] built + exported.")
    print(f"  animated model : {glb_path}")
    print(f"  editable scene : {blend_path}")
    print(f"  frames         : 0..{FRAME_END} @ {FPS}fps "
          f"({FRAME_END / FPS:.1f}s loop)")
    print("  next: convert .glb -> .usdz for SceneKit/RealityKit.")
    print("=" * 60)


main()
