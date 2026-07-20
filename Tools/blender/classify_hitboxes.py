"""
Bucket Z-Anatomy object AABBs into the app's 40 MuscleGroups, unioning each
group into ONE hit box. Companion to classify_head_hitboxes.py (sub-heads).

Pipeline:
    1. In Blender: run extract_hitboxes.py -> /tmp/body_part_hitboxes.json
    2. python3 Tools/blender/classify_hitboxes.py -> /tmp/musclegroup_hitboxes.json
    3. Copy to Resources/musclegroup_hitboxes.json, rebuild.

Classification rules (EXCLUDE / RULES / side_of) live in muscle_classification.py
so the visual muscle mesh (export_muscle_obj.py) is built from exactly the same
objects these hitboxes are.
"""

import json
from collections import defaultdict

from muscle_classification import RULES, classify_group, is_excluded, apply_recentre_correction

d = json.load(open("/tmp/body_part_hitboxes.json"))

# --- Correct a bad whole-body recentering pivot -----------------------------
# extract_hitboxes.py's recentre/scale can be skewed by non-anatomical scene-
# organisation helpers (category folders ".g", cross-section planes). Redo the
# recentre from trustworthy objects only — equivalent to excluding those from
# the start, without re-running Blender. (See muscle_classification.py.)
d, correction_center, correction_scale, excluded_markers = apply_recentre_correction(d)

print(f"Excluded {excluded_markers} non-anatomical scene-organisation objects "
      f"(category folders, cross-section planes) from the recentering fix")
print(f"Corrected centre: {[round(c, 3) for c in correction_center]}, "
      f"rescale factor: {correction_scale:.4f}\n")
# --- end correction -----------------------------------------------------

matched = defaultdict(list)   # MuscleGroup raw value -> list of (name, box)
unmatched_muscle_like = []
excluded_count = 0

for name, box in d.items():
    low = name.lower()
    hit_group = classify_group(name)
    if hit_group:
        matched[hit_group].append((name, box))
    else:
        # `classify_group` returns None both for excluded structures and for
        # genuinely-unmatched muscles; split them apart for the report.
        if is_excluded(name):
            excluded_count += 1
        elif 'muscle' in low:
            # The literal word "muscle" is a solid signal this is skeletal
            # muscle we failed to bucket (vs. bone/vessel/nerve names that just
            # end in a Latin-looking suffix).
            unmatched_muscle_like.append(name)

print(f"Total objects: {len(d)}")
print(f"Excluded (non-muscular systems): {excluded_count}")
print(f"Matched into {len(matched)} of 40 MuscleGroup buckets, {sum(len(v) for v in matched.values())} source objects total")
print()
for group, items in sorted(matched.items()):
    print(f"  {group}: {len(items)} objects")
print()
print(f"Unmatched 'muscle-like' leftovers (first 40 of {len(unmatched_muscle_like)}):")
for n in unmatched_muscle_like[:40]:
    print("   -", n)

# Union boxes per group and write final output matching MuscleGroups.swift.
#
# LEFT/RIGHT CONVENTION: Z-Anatomy's ".l"/".r" suffixes are anatomical (the
# model's own left/right) — and since the 3D marking redesign the app uses the
# SAME anatomical convention: "Left Biceps" is the figure's own left arm
# (world +X, since the model faces +Z) at every camera angle. The old 2D body
# map used screen-side ("mirror") naming and this used to swap sides to match;
# that swap is deliberately gone. Do not reintroduce it — HitboxDataTests pins
# Left = positive-x.
def app_side_swap(group_name: str) -> str:
    return group_name

final = {}
for group, items in matched.items():
    mins = [b['min'] for _, b in items]
    maxs = [b['max'] for _, b in items]
    lo = [min(m[i] for m in mins) for i in range(3)]
    hi = [max(m[i] for m in maxs) for i in range(3)]
    final[app_side_swap(group)] = {"min": lo, "max": hi, "source_object_count": len(items)}

import os
_OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated")
os.makedirs(_OUT_DIR, exist_ok=True)
with open(os.path.join(_OUT_DIR, "musclegroup_hitboxes.json"), "w") as f:
    json.dump(final, f, indent=2)
print()
print(f"Wrote {len(final)}-group unioned hitboxes to {os.path.join(_OUT_DIR, 'musclegroup_hitboxes.json')}")

ALL_GROUPS = [app_side_swap(g) for g, _ in RULES]
missing = [g for g in ALL_GROUPS if g not in final]
print(f"\nMuscleGroups with ZERO matched objects ({len(missing)}): {missing}")

print("\nSymmetry check (Left/Right x-ranges should NOT overlap):")
base_names = sorted({g[5:] for g in final if g.startswith("Left ")})
for base in base_names:
    l, r = final.get(f"Left {base}"), final.get(f"Right {base}")
    if not l or not r:
        continue
    overlap = l['min'][0] < r['max'][0] and r['min'][0] < l['max'][0]
    flag = "  <-- OVERLAP" if overlap else ""
    print(f"  {base:12} L x[{l['min'][0]:+.3f},{l['max'][0]:+.3f}]  "
          f"R x[{r['min'][0]:+.3f},{r['max'][0]:+.3f}]{flag}")
