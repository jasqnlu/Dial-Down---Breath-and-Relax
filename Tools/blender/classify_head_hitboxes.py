"""
Generate anatomical SUB-HEAD hit boxes (e.g. the three heads of the triceps),
as a companion to classify_hitboxes.py which unions each muscle into ONE box.

Pipeline (same two-step shape as the group boxes):

    1. In Blender, run extract_hitboxes.py  ->  /tmp/body_part_hitboxes.json
       (per-object world AABBs, already remapped into the app's normalized
       Y-up / +Z-forward, height-2, recentred model space).
    2. Run this script (plain Python, no Blender needed):
           python3 Tools/blender/classify_head_hitboxes.py
       -> /tmp/musclegroup_head_hitboxes.json
    3. Copy the result to:
           Breath - Relax & Stretch/Resources/musclegroup_head_hitboxes.json
       Rebuild — heads now surface as disambiguation candidates automatically
       (BodyHitVolumes.all loads this file; empty {} until you populate it).

The emitted names MUST match `MuscleGroup.muscleHeads` in
Models/MuscleGroups.swift exactly, e.g. "Left Triceps Long Head",
"Right Vastus Lateralis". Boxes are nested INSIDE the parent muscle box, so
MuscleHitResolver's smallest-volume tiebreak makes a tap resolve to the head,
and confirm-step disambiguation drops the redundant parent group.

HEAD_RULES / side_of live in muscle_classification.py (shared with the group
hitboxes and the visual muscle-mesh export). Extend HEAD_RULES there if a head
isn't recognised — the unmatched-'muscle'/'head' report below flags candidates.
"""

import json
from collections import defaultdict

from muscle_classification import HEAD_RULES, classify_head, side_of, is_excluded, apply_recentre_correction

SRC = "/tmp/body_part_hitboxes.json"
OUT = "/tmp/musclegroup_head_hitboxes.json"

d = json.load(open(SRC))

# --- Correct the whole-body recentre pivot (identical to classify_hitboxes.py):
# exclude the non-anatomical Z-Anatomy scene-organisation helpers so left and
# right land on opposite sides of the midline. -----------------------------
d, _center, _scale, _excluded = apply_recentre_correction(d)
# --- end correction --------------------------------------------------------

matched = defaultdict(list)       # "Left Triceps Long Head" -> [(name, box), …]
unmatched_muscle_like = []

for name, box in d.items():
    # Mirror the original flow exactly: drop excluded structures and objects
    # with no unambiguous .l/.r side BEFORE the leftover report, so the report
    # only ever lists sided muscles we genuinely failed to bucket as a head.
    if is_excluded(name):
        continue
    if not side_of(name):
        continue
    head_name = classify_head(name)
    if head_name:
        matched[head_name].append((name, box))
    elif 'muscle' in name.lower() and 'head' in name.lower():
        unmatched_muscle_like.append(name)

# Union the source objects that make up each head into one AABB.
final = {}
for head_name, items in matched.items():
    mins = [b['min'] for _, b in items]
    maxs = [b['max'] for _, b in items]
    lo = [min(m[i] for m in mins) for i in range(3)]
    hi = [max(m[i] for m in maxs) for i in range(3)]
    final[head_name] = {"min": lo, "max": hi, "source_object_count": len(items)}

with open(OUT, "w") as f:
    json.dump(final, f, indent=2)

print(f"Matched {len(matched)} head buckets from {sum(len(v) for v in matched.values())} objects")
for head_name, items in sorted(matched.items()):
    print(f"  {head_name}: {len(items)} objects")
print(f"\nWrote {len(final)} head hit boxes to {OUT}")
print("Copy to Resources/musclegroup_head_hitboxes.json when the buckets look right.\n")

if unmatched_muscle_like:
    print(f"Unmatched 'muscle'/'head' leftovers ({len(unmatched_muscle_like)}) — "
          f"extend HEAD_RULES if any of these are heads you want:")
    for n in unmatched_muscle_like[:40]:
        print("   -", n)

# Symmetry sanity check: Left/Right of the same head shouldn't overlap in x.
print("\nSymmetry check (Left/Right x-ranges should NOT overlap):")
bases = sorted({n[len("Left "):] for n in final if n.startswith("Left ")})
for base in bases:
    l, r = final.get(f"Left {base}"), final.get(f"Right {base}")
    if not l or not r:
        print(f"  {base:22} MISSING {'Right' if l else 'Left'} side")
        continue
    overlap = l['min'][0] < r['max'][0] and r['min'][0] < l['max'][0]
    flag = "  <-- OVERLAP (check side suffixes)" if overlap else ""
    print(f"  {base:22} L x[{l['min'][0]:+.3f},{l['max'][0]:+.3f}]  "
          f"R x[{r['min'][0]:+.3f},{r['max'][0]:+.3f}]{flag}")
