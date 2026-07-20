# Anatomy Data Pipeline Implementation Plan (Plan 1 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Blender→app export/hitbox pipeline that turns `Z-AnatomyMuscle-Joint-Skin-Merged.blend` into the single anatomy model's assets — `BodyAnatomy.obj`, `anatomy_node_names.json`, and regenerated muscle/head/joint/face hitboxes (with the new 15-region joint set + facial-muscle face zones) — and verify them with a pure-Python harness.

**Architecture:** Extend the existing pure-Python `muscle_classification.py` with `classify_face_zone` + `classify_joint`; add `classify_joint_hitboxes.py` (real joint-capsule geometry) and extend `classify_head_hitboxes.py` (face zones); evolve `export_muscle_obj.py` → `export_anatomy.py` (selects by the three whitelisted collections, tags four object classes). All outputs are written to a **staging dir `Tools/blender/generated/`** — NOT `Resources/` — so the Xcode build/test suite stays green throughout Plan 1. A `verify_anatomy_export.py` harness (pure Python, no Blender) gates coverage, no-leakage, mesh↔hitbox alignment, and the L=+x convention. Plan 2 moves the staged assets into `Resources/` alongside the Swift wiring, test updates, and rendering.

**Tech Stack:** Blender 5.x headless Python (`/Applications/Blender.app/Contents/MacOS/Blender -b`), plain Python 3 (stdlib only — no pytest/numpy), JSON.

## Global Constraints

- **Blender invocation:** `/Applications/Blender.app/Contents/MacOS/Blender -b "/Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend" --python <script>` (headless). The blend is not in the repo (large, gitignored).
- **Source blend is the FULL Z-Anatomy atlas** (6,987 objects, all systems). Select by **collection membership + name classification, never by Blender visibility flags.** The three whitelisted collections: `4: Muscular system`, `3: Joints`, `Regions of head`.
- **Coordinate space:** Y-up, +Z-forward, height 2.0, recentred to whole-body bbox center. Normalization (`blender_to_app` axis map + whole-body recentre/scale + `apply_recentre_correction` second pass) is computed over **all non-`.g` meshes** in the blend — identically for the mesh export and the hitbox extract, so mesh ⟷ hitboxes align by construction.
- **Left = anatomical left = world +x** (figure faces +Z). Pinned by tests; never reintroduce screen-mirror swapping.
- **Joint region vocabulary (15):** midline `Neck` (cervical discs C2-C3…C7-T1), `Upper Spine` (thoracic T1-T2…T12-L1), `Lower Spine` (lumbar L1-L2…L5-S1); bilateral `Left/Right Shoulder Joint`, `Left/Right Elbow`, `Left/Right Wrist`, `Left/Right Hip`, `Left/Right Knee`, `Left/Right Ankle`. Names must NOT collide with any `MuscleGroup` raw value (hence `Shoulder Joint`, not `Shoulder`).
- **Face zones (4):** Eye→orbicularis oculi, Temple→temporalis, Jaw→masseter, Forehead→frontalis. Bilateral zones expand to `Left/Right <Zone>`; `Forehead` is midline (no side). Names match `MuscleGroup.muscleHeads` keys: `Left/Right Eye`, `Left/Right Temple`, `Left/Right Jaw`, `Forehead`.
- **Excluded from export:** bones, organs, nerves, vessels, lymph, `.g` category anchors, `Cross Section` planes, and any object matching none of the classifiers.
- **Asset budget:** staged `BodyAnatomy.obj` ≤ ~18 MB. Per-object decimate ratio default 0.15; decimate `Hairs of head` (8.6k polys) hard.
- **Staging dir:** all Plan 1 outputs go to `Tools/blender/generated/`. Do not write to `Breath - Relax & Stretch/Resources/` in Plan 1.

---

### Task 1: `classify_face_zone` + `classify_joint` in `muscle_classification.py`

**Files:**
- Modify: `Tools/blender/muscle_classification.py` (add rules + two functions + one helper, after `classify_head`)
- Test: `Tools/blender/test_classification.py` (new; plain-`python3` asserts, stdlib only)

**Interfaces:**
- Consumes: existing `side_of(name) -> 'l'|'r'|''`, `SIDE_WORD`, `re`.
- Produces:
  - `classify_face_zone(name: str) -> str | None` — `"Left Eye"`, `"Right Temple"`, `"Left Jaw"`, `"Forehead"`, or `None`.
  - `classify_joint(name: str) -> str | None` — one of the 15 joint region names, or `None`.

- [ ] **Step 1: Write the failing test** — create `Tools/blender/test_classification.py`:

```python
"""Pure-Python unit tests for the Z-Anatomy name classifiers.
Run: python3 Tools/blender/test_classification.py   (stdlib only, no Blender)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from muscle_classification import classify_face_zone, classify_joint

def check(actual, expected, label):
    assert actual == expected, f"{label}: got {actual!r}, expected {expected!r}"

def test_face_zones():
    check(classify_face_zone("Orbital part of orbicularis oculi.l"), "Left Eye", "eye.l")
    check(classify_face_zone("Palpebral part of orbicularis oculi.r"), "Right Eye", "eye.r")
    check(classify_face_zone("Temporalis muscle.l"), "Left Temple", "temple.l")
    check(classify_face_zone("Deep part of masseter.r"), "Right Jaw", "jaw.r")
    check(classify_face_zone("Frontalis muscle.l"), "Forehead", "forehead.l->midline")
    check(classify_face_zone("Frontalis muscle.r"), "Forehead", "forehead.r->midline")
    # Fascia / region skin patches are NOT facial muscles.
    check(classify_face_zone("Masseteric fascia.l"), None, "masseteric fascia")
    check(classify_face_zone("Parotideomasseteric region.l"), None, "masseter region")
    # Insertion markers (.o2l etc.) have no trustworthy side -> skipped.
    check(classify_face_zone("Temporalis muscle.o2l"), None, "temporalis insertion")
    check(classify_face_zone("Biceps brachii muscle.l"), None, "non-face muscle")

def test_joints():
    check(classify_joint("Articular capsule of glenohumeral joint.l"), "Left Shoulder Joint", "gh.l")
    check(classify_joint("Articular capsule of acromioclavicular joint.r"), "Right Shoulder Joint", "ac.r")
    check(classify_joint("Articular capsule of elbow joint.l"), "Left Elbow", "elbow.l")
    check(classify_joint("Annular ligament of radius.r"), "Right Elbow", "annular.r")
    check(classify_joint("Articular capsule of radiocarpal joint.l"), "Left Wrist", "wrist.l")
    check(classify_joint("Articular capsule of hip joint.r"), "Right Hip", "hip.r")
    check(classify_joint("Anterior cruciate ligament.l"), "Left Knee", "acl.l")
    check(classify_joint("Medial meniscus.r"), "Right Knee", "meniscus.r")
    check(classify_joint("Anterior talofibular ligament.l"), "Left Ankle", "ankle.l")
    # Spine buckets by the FIRST vertebra letter of the disc level.
    check(classify_joint("Intervertebral disc C5-C6"), "Neck", "cervical disc")
    check(classify_joint("Nucleus pulposus C7-T1"), "Neck", "cervicothoracic -> neck")
    check(classify_joint("Intervertebral disc T4-T5"), "Upper Spine", "thoracic disc")
    check(classify_joint("Intervertebral disc T12-L1"), "Upper Spine", "T12-L1 -> upper")
    check(classify_joint("Intervertebral disc L4-L5"), "Lower Spine", "lumbar disc")
    check(classify_joint("Nucleus pulposus L5-S1"), "Lower Spine", "L5-S1 -> lower")
    # Non-kept joints and label anchors -> None.
    check(classify_joint("Articular capsules of metacarpophalangeal joints"), None, "finger joints")
    check(classify_joint("Hip joint.j"), None, "label anchor (no side)")
    check(classify_joint("Biceps brachii muscle.l"), None, "muscle, not joint")

if __name__ == "__main__":
    test_face_zones(); test_joints()
    print("OK: classification tests passed")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 "Tools/blender/test_classification.py"`
Expected: FAIL with `ImportError: cannot import name 'classify_face_zone'`.

- [ ] **Step 3: Add the rules + functions to `muscle_classification.py`** — insert after `classify_head` (before `apply_recentre_correction`):

```python
# --- Face zones ------------------------------------------------------------
# (base zone, bilateral?, name patterns). Face zones tag facial MUSCLES that
# also belong to the coarse "Head" group; names match MuscleGroup.muscleHeads.
FACE_ZONE_RULES = [
    ("Eye",      True,  [r"orbicularis oculi"]),
    ("Temple",   True,  [r"temporalis"]),
    ("Jaw",      True,  [r"masseter"]),
    ("Forehead", False, [r"frontalis"]),
]
# Skin/fascia patches that share a facial-muscle keyword but are NOT the muscle.
FACE_ZONE_EXCLUDE = ("fascia", "region", "aponeurosis")


def classify_face_zone(name: str):
    """Face zone ("Left Eye"/"Forehead") for a facial-muscle object, else None."""
    low = name.lower()
    if any(x in low for x in FACE_ZONE_EXCLUDE):
        return None
    side = side_of(name)
    for base, bilateral, patterns in FACE_ZONE_RULES:
        if any(re.search(p, low) for p in patterns):
            if bilateral:
                return f"{SIDE_WORD[side]} {base}" if side else None
            return base
    return None


# --- Joints ----------------------------------------------------------------
# Bilateral joints: (region base, patterns). Side comes from .l/.r. Patterns are
# scoped so they don't cross-match (e.g. wrist collaterals say "of wrist"; elbow
# relies on its capsule + annular ligament rather than bare "collateral").
JOINT_BILATERAL_RULES = [
    ("Shoulder Joint", [r"glenohumeral", r"acromioclavicular", r"coracohumeral",
                        r"coraco-acromial", r"glenoid labrum", r"transverse humeral ligament"]),
    ("Elbow",          [r"capsule of elbow", r"annular ligament of radius",
                        r"\bquadrate ligament\b", r"oblique cord"]),
    ("Wrist",          [r"radiocarpal", r"collateral ligament of wrist", r"ulnocarpal",
                        r"radioscaph", r"radiate carpal", r"ulnolunate", r"ulnotriquetral"]),
    ("Hip",            [r"capsule of hip", r"iliofemoral", r"pubofemoral", r"ischiofemoral",
                        r"ligament of head of femur", r"zona orbicularis", r"acetabular"]),
    ("Knee",           [r"capsule of knee", r"cruciate ligament", r"fibular collateral ligament",
                        r"tibial collateral ligament", r"meniscus", r"meniscotibial",
                        r"popliteal ligament", r"transverse ligament of knee", r"infrapatellar"]),
    ("Ankle",          [r"talofibular", r"calcaneofibular", r"tibiotalar", r"tibiocalcaneal",
                        r"tibionavicular", r"collateral ligament of ankle", r"talocalcaneal",
                        r"ankle joint"]),
]
_SPINE_LETTER = {"c": "Neck", "t": "Upper Spine", "l": "Lower Spine"}


def _spine_region(low: str):
    """Neck/Upper Spine/Lower Spine from a disc/nucleus level, bucketed by the
    FIRST vertebra letter (so C7-T1 -> Neck, T12-L1 -> Upper Spine)."""
    m = re.search(r"(?:intervertebral disc|nucleus pulposus)\s+([ctl])\d", low)
    return _SPINE_LETTER.get(m.group(1)) if m else None


def classify_joint(name: str):
    """One of the 15 kept joint region names for a joint object, else None."""
    low = name.lower()
    spine = _spine_region(low)
    if spine:
        return spine
    if re.search(r"atlanto-axial|atlanto-occipital", low):
        return "Neck"
    side = side_of(name)
    for base, patterns in JOINT_BILATERAL_RULES:
        if any(re.search(p, low) for p in patterns):
            return f"{SIDE_WORD[side]} {base}" if side else None
    return None
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 "Tools/blender/test_classification.py"`
Expected: `OK: classification tests passed`

- [ ] **Step 5: Commit**

```bash
git add "Tools/blender/muscle_classification.py" "Tools/blender/test_classification.py"
git commit -m "feat(blender): add classify_face_zone + classify_joint classifiers"
```

---

### Task 2: `classify_joint_hitboxes.py` — real-geometry joint boxes

**Files:**
- Create: `Tools/blender/classify_joint_hitboxes.py`
- Test: `Tools/blender/test_classification.py` (append `test_joint_bucketing`)

**Interfaces:**
- Consumes: `classify_joint` (Task 1), `apply_recentre_correction` (existing), a per-object AABB dict shaped `{name: {"min":[x,y,z], "max":[x,y,z]}}` (extract output).
- Produces: `bucket_joint_boxes(corrected: dict) -> dict` returning `{region: {"min":[..],"max":[..]}}`; writes `Tools/blender/generated/joint_hitboxes.json` when run as `__main__`.

- [ ] **Step 1: Write the failing test** — append to `Tools/blender/test_classification.py` (and add its call in `__main__`):

```python
def test_joint_bucketing():
    from classify_joint_hitboxes import bucket_joint_boxes
    fixture = {
        # two objects of the same joint on the left -> unioned into one box
        "Articular capsule of elbow joint.l": {"min": [0.10, 0.20, -0.02], "max": [0.20, 0.30, 0.02]},
        "Annular ligament of radius.l":       {"min": [0.15, 0.18, -0.03], "max": [0.22, 0.24, 0.01]},
        # right elbow -> separate bucket
        "Articular capsule of elbow joint.r": {"min": [-0.20, 0.20, -0.02], "max": [-0.10, 0.30, 0.02]},
        # cervical disc -> Neck
        "Intervertebral disc C5-C6":          {"min": [-0.03, 0.55, -0.05], "max": [0.03, 0.60, 0.02]},
        # non-kept -> dropped
        "Articular capsules of metacarpophalangeal joints": {"min": [0, 0, 0], "max": [0.01, 0.01, 0.01]},
    }
    out = bucket_joint_boxes(fixture)
    check(set(out.keys()), {"Left Elbow", "Right Elbow", "Neck"}, "joint buckets")
    # Left Elbow unions both left objects.
    check(out["Left Elbow"]["min"], [0.10, 0.18, -0.03], "left elbow min union")
    check(out["Left Elbow"]["max"], [0.22, 0.30, 0.02], "left elbow max union")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 "Tools/blender/test_classification.py"`
Expected: FAIL with `ModuleNotFoundError: No module named 'classify_joint_hitboxes'`.

- [ ] **Step 3: Create `Tools/blender/classify_joint_hitboxes.py`:**

```python
"""Derive the 15-region joint hit boxes from REAL Z-Anatomy joint geometry
(capsules/ligaments/discs), replacing the hand-placed boxes.

Pipeline (same two-step shape as classify_hitboxes.py):
    1. In Blender: extract_hitboxes.py -> /tmp/body_part_hitboxes.json
    2. python3 Tools/blender/classify_joint_hitboxes.py
       -> Tools/blender/generated/joint_hitboxes.json
Buckets each joint object by classify_joint and unions each region into one AABB.
Same normalized model space as the muscle/head boxes (shared apply_recentre_
correction), so all boxes align with BodyAnatomy.obj.
"""
import json
import os
from collections import defaultdict

from muscle_classification import classify_joint, apply_recentre_correction

SRC = "/tmp/body_part_hitboxes.json"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated")
OUT = os.path.join(OUT_DIR, "joint_hitboxes.json")


def bucket_joint_boxes(corrected: dict) -> dict:
    """{name: box} -> {joint region: unioned box}. Ignores non-kept joints."""
    matched = defaultdict(list)
    for name, box in corrected.items():
        region = classify_joint(name)
        if region:
            matched[region].append(box)
    final = {}
    for region, boxes in matched.items():
        final[region] = {
            "min": [min(b["min"][i] for b in boxes) for i in range(3)],
            "max": [max(b["max"][i] for b in boxes) for i in range(3)],
        }
    return final


if __name__ == "__main__":
    d = json.load(open(SRC))
    corrected, _c, _s, _n = apply_recentre_correction(d)
    final = bucket_joint_boxes(corrected)
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT, "w") as f:
        json.dump(final, f, indent=2)
    print(f"Wrote {len(final)} joint regions to {OUT}")
    for region in sorted(final):
        b = final[region]
        cx = (b["min"][0] + b["max"][0]) / 2
        print(f"  {region:22} center x={cx:+.3f}")
    expected = (["Neck", "Upper Spine", "Lower Spine"]
                + [f"{s} {j}" for s in ("Left", "Right")
                   for j in ("Shoulder Joint", "Elbow", "Wrist", "Hip", "Knee", "Ankle")])
    missing = [r for r in expected if r not in final]
    print(f"\nMissing joint regions ({len(missing)}): {missing}")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 "Tools/blender/test_classification.py"`
Expected: `OK: classification tests passed`

- [ ] **Step 5: Commit**

```bash
git add "Tools/blender/classify_joint_hitboxes.py" "Tools/blender/test_classification.py"
git commit -m "feat(blender): classify_joint_hitboxes derives 15 joint regions from real geometry"
```

---

### Task 3: Extend `classify_head_hitboxes.py` to emit face-zone boxes

**Files:**
- Modify: `Tools/blender/classify_head_hitboxes.py`

**Interfaces:**
- Consumes: `classify_face_zone` (Task 1), existing `classify_head`, `apply_recentre_correction`.
- Produces: `/tmp/musclegroup_head_hitboxes.json` now containing muscle sub-heads AND the 4/7 face-zone boxes (`Left/Right Eye`, `Left/Right Temple`, `Left/Right Jaw`, `Forehead`).

- [ ] **Step 1: Modify the matching loop** — in `classify_head_hitboxes.py`, replace the `for name, box in d.items():` loop body so a face zone is also bucketed (a facial muscle matches BOTH `classify_head`→None and `classify_face_zone`→a zone). Change the loop to:

```python
for name, box in d.items():
    if is_excluded(name):
        continue
    zone = classify_face_zone(name)          # face zones first (masseter/temporalis/…)
    if zone:
        matched[zone].append((name, box))
        continue
    if not side_of(name):
        continue
    head_name = classify_head(name)
    if head_name:
        matched[head_name].append((name, box))
    elif 'muscle' in name.lower() and 'head' in name.lower():
        unmatched_muscle_like.append(name)
```

- [ ] **Step 2: Update the import** — change the import line to include `classify_face_zone`:

```python
from muscle_classification import (HEAD_RULES, classify_head, classify_face_zone,
                                    side_of, is_excluded, apply_recentre_correction)
```

- [ ] **Step 3: Redirect the output to the staging dir** — change `OUT` so Plan 1 never writes into `Resources/`:

```python
import os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated",
                   "musclegroup_head_hitboxes.json")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
```

(Its verification runs against the merged blend in Task 5; there is no standalone unit test because it needs the extract dump. Coverage is asserted by `verify_anatomy_export.py` in Task 6.)

- [ ] **Step 4: Commit**

```bash
git add "Tools/blender/classify_head_hitboxes.py"
git commit -m "feat(blender): classify_head_hitboxes also emits facial-muscle face-zone boxes"
```

---

### Task 4: `export_anatomy.py` — single-model OBJ + node map

**Files:**
- Create: `Tools/blender/export_anatomy.py` (evolves `export_muscle_obj.py`; the old script stays for now)

**Interfaces:**
- Consumes: `classify_group`, `classify_head`, `classify_face_zone`, `classify_joint`, `apply_recentre_correction`, `NON_ANATOMICAL` (all from `muscle_classification`).
- Produces (in `Tools/blender/generated/`): `BodyAnatomy.obj` (one `o` group per kept object) and `anatomy_node_names.json` shaped `{"nodes": {node: {"layer": "muscle"|"joint"|"headSkin", "group"?, "head"?, "faceZone"?, "joint"?}}}`.

- [ ] **Step 1: Create `export_anatomy.py`** by copying `export_muscle_obj.py` and applying these changes (full file):

```python
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
```

- [ ] **Step 2: Commit** (it can only be exercised in Blender in Task 5)

```bash
git add "Tools/blender/export_anatomy.py"
git commit -m "feat(blender): export_anatomy builds single muscle+joint+headSkin model"
```

---

### Task 5: Run the pipeline against the merged blend (generate staged assets)

**Files:**
- Generated: `Tools/blender/generated/{BodyAnatomy.obj, anatomy_node_names.json, musclegroup_hitboxes.json, musclegroup_head_hitboxes.json, joint_hitboxes.json}`
- Modify (staging redirect only): `Tools/blender/classify_hitboxes.py` — write its output to `Tools/blender/generated/musclegroup_hitboxes.json` instead of `/tmp` (mirror Task 3's redirect), so all five assets land in one staging dir.

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces: five staged asset files, verified in Task 6.

- [ ] **Step 1: Redirect `classify_hitboxes.py` output to the staging dir** — change its final `open("/tmp/musclegroup_hitboxes.json", "w")` to:

```python
import os
_OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated")
os.makedirs(_OUT_DIR, exist_ok=True)
with open(os.path.join(_OUT_DIR, "musclegroup_hitboxes.json"), "w") as f:
    json.dump(final, f, indent=2)
```

- [ ] **Step 2: Extract per-object AABBs from the merged blend**

Run:
```bash
"/Applications/Blender.app/Contents/MacOS/Blender" -b \
  "/Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend" \
  --python "Tools/blender/extract_hitboxes.py"
```
Expected: `Wrote <N> object bounding boxes to /tmp/body_part_hitboxes.json` where N is in the thousands (full atlas).

- [ ] **Step 3: Classify muscle / head+face / joint hitboxes** (pure Python, reads the dump)

Run:
```bash
cd Tools/blender
python3 classify_hitboxes.py
python3 classify_head_hitboxes.py
python3 classify_joint_hitboxes.py
cd ../..
```
Expected: each prints its bucket counts; `classify_joint_hitboxes.py` prints `Missing joint regions (0): []`. If any region is missing, extend the matching rules in `muscle_classification.py` (re-run Task 1's test) and re-run.

- [ ] **Step 4: Export the mesh + node map**

Run:
```bash
"/Applications/Blender.app/Contents/MacOS/Blender" -b \
  "/Users/jasonlu/Blender/Z-AnatomyMuscle-Joint-Skin-Merged.blend" \
  --python "Tools/blender/export_anatomy.py"
```
Expected: `Layer counts: {'muscle': …, 'joint': …, 'headSkin': …}` with all three layers non-zero.

- [ ] **Step 5: Check the asset size**

Run: `ls -la "Tools/blender/generated/BodyAnatomy.obj"`
Expected: ≤ ~18 MB. If larger, re-run Task 5 Step 4 with a lower ratio (`--python export_anatomy.py -- 0.10`) and re-check.

- [ ] **Step 6: Commit the staged assets**

```bash
git add "Tools/blender/classify_hitboxes.py" "Tools/blender/generated/"
git commit -m "chore(blender): generate staged anatomy assets from merged blend"
```

---

### Task 6: `verify_anatomy_export.py` — coverage + alignment harness

**Files:**
- Create: `Tools/blender/verify_anatomy_export.py` (pure Python, no Blender; operates on `Tools/blender/generated/`)

**Interfaces:**
- Consumes: the five staged assets + `muscle_classification` (for `EXCLUDE`) + the app vocabulary constants (hard-coded here to avoid a Swift dependency).
- Produces: exit 0 + `OK` on success; a non-zero exit with the first failing assertion otherwise.

- [ ] **Step 1: Create the harness:**

```python
"""Verify the staged anatomy assets (no Blender needed):
    python3 Tools/blender/verify_anatomy_export.py
Checks coverage, no excluded-system leakage, mesh<->hitbox alignment, L=+x."""
import json, os, re, sys

GEN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated")

MUSCLE_GROUPS = {  # MuscleGroup.allCases raw values
    "Front Neck","Back Neck","Left Trapezius","Right Trapezius","Left Shoulder","Right Shoulder",
    "Left Chest","Right Chest","Abs","Left Obliques","Right Obliques","Left Lats","Right Lats",
    "Spinal Erectors","Lower Back","Left Biceps","Right Biceps","Left Triceps","Right Triceps",
    "Left Forearm","Right Forearm","Left Glutes","Right Glutes","Left Hip Flexors","Right Hip Flexors",
    "Left Adductors","Right Adductors","Left Quadriceps","Right Quadriceps","Left Hamstrings",
    "Right Hamstrings","Left Calves","Right Calves","Left Tibialis","Right Tibialis","Head",
    "Left Hand","Right Hand","Left Foot","Right Foot",
}
FACE_ZONES = {"Left Eye","Right Eye","Left Temple","Right Temple","Left Jaw","Right Jaw","Forehead"}
JOINT_REGIONS = {"Neck","Upper Spine","Lower Spine"} | {
    f"{s} {j}" for s in ("Left","Right")
    for j in ("Shoulder Joint","Elbow","Wrist","Hip","Knee","Ankle")}
LEAK = ("bone","nerve","vein","artery","node","cochlea","tooth","teeth","ventricle","gland")


def load(name):
    return json.load(open(os.path.join(GEN, name)))


def parse_obj_centroids(path):
    """node name -> (cx,cy,cz) centroid of its vertices."""
    cur, acc = None, {}
    for line in open(path):
        if line.startswith("o "):
            cur = line[2:].strip()
            acc[cur] = [0.0, 0.0, 0.0, 0]
        elif line.startswith("v ") and cur:
            _, x, y, z = line.split()[:4]
            a = acc[cur]; a[0]+=float(x); a[1]+=float(y); a[2]+=float(z); a[3]+=1
    return {n: (a[0]/a[3], a[1]/a[3], a[2]/a[3]) for n, a in acc.items() if a[3]}


def inside(box, p, eps=0.02):
    return all(box["min"][i]-eps <= p[i] <= box["max"][i]+eps for i in range(3))


def main():
    nodes = load("anatomy_node_names.json")["nodes"]
    groups = load("musclegroup_hitboxes.json")
    heads = load("musclegroup_head_hitboxes.json")
    joints = load("joint_hitboxes.json")
    centroids = parse_obj_centroids(os.path.join(GEN, "BodyAnatomy.obj"))

    # 1. OBJ <-> node map are the same set.
    assert set(centroids) == set(nodes), (
        f"OBJ nodes != map nodes; only-in-obj={set(centroids)-set(nodes)}, "
        f"only-in-map={set(nodes)-set(centroids)}")

    # 2. No excluded-system leakage in any node name.
    for n in nodes:
        low = n.lower()
        assert not any(k in low for k in LEAK), f"leaked excluded structure: {n}"

    # 3. Coverage: every group / face zone / joint region has >=1 node AND >=1 box.
    covered_groups = {e.get("group") for e in nodes.values() if e.get("group")}
    covered_zones = {e.get("faceZone") for e in nodes.values() if e.get("faceZone")}
    covered_joints = {e.get("joint") for e in nodes.values() if e.get("joint")}
    assert MUSCLE_GROUPS <= covered_groups, f"groups w/o node: {MUSCLE_GROUPS-covered_groups}"
    assert FACE_ZONES <= covered_zones, f"zones w/o node: {FACE_ZONES-covered_zones}"
    assert JOINT_REGIONS <= covered_joints, f"joints w/o node: {JOINT_REGIONS-covered_joints}"
    assert MUSCLE_GROUPS <= set(groups), f"groups w/o box: {MUSCLE_GROUPS-set(groups)}"
    assert FACE_ZONES <= set(heads), f"zones w/o box: {FACE_ZONES-set(heads)}"
    assert JOINT_REGIONS == set(joints), f"joint box set != expected: {set(joints)^JOINT_REGIONS}"

    # 4. L=+x / R=-x for every sided box.
    for coll in (groups, heads, joints):
        for name, box in coll.items():
            cx = (box["min"][0] + box["max"][0]) / 2
            if name.startswith("Left "):  assert cx > 0, f"{name} L but x={cx:.3f}"
            if name.startswith("Right "): assert cx < 0, f"{name} R but x={cx:.3f}"

    # 5. Alignment: each node centroid lies inside its region's box.
    def box_for(entry):
        if entry.get("joint"): return joints.get(entry["joint"])
        if entry.get("faceZone"): return heads.get(entry["faceZone"])
        if entry.get("head"): return heads.get(entry["head"])
        if entry.get("group"): return groups.get(entry["group"])
        return None  # headSkin has no region box
    misaligned = []
    for node, entry in nodes.items():
        box = box_for(entry)
        if box and not inside(box, centroids[node]):
            misaligned.append(node)
    assert not misaligned, f"{len(misaligned)} nodes outside their box, e.g. {misaligned[:5]}"

    print(f"OK: {len(nodes)} nodes, {len(groups)} groups, {len(heads)} head/zone boxes, "
          f"{len(joints)} joint boxes verified")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print("VERIFY FAILED:", e); sys.exit(1)
```

- [ ] **Step 2: Run the harness**

Run: `python3 "Tools/blender/verify_anatomy_export.py"`
Expected: `OK: … nodes, 40 groups, … head/zone boxes, 15 joint boxes verified`.
If it fails on coverage, extend the relevant classifier rules (Task 1) and re-run Task 5. If it fails on alignment for a headSkin-adjacent node, that node is fine (headSkin has no box → skipped); investigate only muscle/joint/zone misalignments.

- [ ] **Step 3: Commit**

```bash
git add "Tools/blender/verify_anatomy_export.py"
git commit -m "test(blender): verify_anatomy_export gates coverage + mesh/hitbox alignment"
```

---

## Self-Review

**Spec coverage (Plan 1 scope = the export/hitbox data layer):**
- Component 1 (`export_anatomy.py`, collection whitelist, 4 classes, `anatomy_node_names.json`) → Tasks 4–5. ✓
- Component 2 (regenerated muscle/head hitboxes + `classify_joint_hitboxes.py` from real geometry + face-zone hitboxes) → Tasks 2, 3, 5. ✓
- `classify_joint` / `classify_face_zone` → Task 1. ✓
- Export-time verification (every group/head/joint/zone has a node + box; every mapped node in OBJ; no excluded leakage; alignment; L=+x) → Task 6. ✓
- **Deferred to Plan 2 (NOT in this plan):** Component 3 Swift vocab (`JointRegion`), Component 4 `RegionAdjacency` + `candidates()`, Component 5 rendering/grayscale/head-skin fade/colorize, Component 6 rotation fix, moving assets into `Resources/`, deleting old assets, all Swift/`xcodebuild` tests, simulator verification.

**Placeholder scan:** none — every step has runnable code/commands.

**Type consistency:** `classify_face_zone`/`classify_joint` signatures match across Tasks 1–4 and the verify harness; `bucket_joint_boxes` shape matches its test and consumer; node-map schema `{layer, group?, head?, faceZone?, joint?}` is consistent between `export_anatomy.py` (Task 4) and `verify_anatomy_export.py` (Task 6).

**Known risk (flagged for Plan 2):** joint boxes built from unioned real geometry may be larger than a small muscle/head box that also contains the joint's center, which would break the Swift `jointCentersResolveToJoints` smallest-volume tiebreak. Task 6 does not assert that property (it needs the full `BodyHitVolumes` set). Plan 2's first data task must run the Swift resolver test and, if a joint loses the tiebreak, tighten `classify_joint` toward capsule-only geometry or shrink the region box — mirroring the tuning the old `make_joint_hitboxes.py` did by hand.
