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
"Right Vastus Lateralis". Side ("Left"/"Right") is taken from the Z-Anatomy
`.l`/`.r` suffix (the model's OWN anatomical side — the app uses the same
convention: Left = world +X at front view). Boxes are nested INSIDE the parent
muscle box, so MuscleHitResolver's smallest-volume tiebreak makes a tap resolve
to the head, and confirm-step disambiguation drops the redundant parent group.

Z-Anatomy naming varies by file version. This script prints a match report and
a list of unmatched "muscle-like" leftovers so you can extend HEAD_RULES if a
head isn't recognised — same debugging loop as classify_hitboxes.py.
"""

import json
import re
from collections import defaultdict

SRC = "/tmp/body_part_hitboxes.json"
OUT = "/tmp/musclegroup_head_hitboxes.json"

d = json.load(open(SRC))

# --- Correct the whole-body recentre pivot (identical to classify_hitboxes.py):
# exclude the 14 non-anatomical Z-Anatomy scene-organisation helpers so left and
# right land on opposite sides of the midline. -----------------------------
NON_ANATOMICAL = re.compile(r'\.g$|^Cross Section')
trusted = {n: b for n, b in d.items() if not NON_ANATOMICAL.search(n)}

t_min = [min(b['min'][i] for b in trusted.values()) for i in range(3)]
t_max = [max(b['max'][i] for b in trusted.values()) for i in range(3)]
correction_center = [(t_min[i] + t_max[i]) / 2 for i in range(3)]
correction_height = t_max[1] - t_min[1]
correction_scale = 2.0 / correction_height if correction_height > 0 else 1.0

def recorrect(box):
    lo = [(box['min'][i] - correction_center[i]) * correction_scale for i in range(3)]
    hi = [(box['max'][i] - correction_center[i]) * correction_scale for i in range(3)]
    return {"min": lo, "max": hi}

d = {n: recorrect(b) for n, b in trusted.items()}
# --- end correction --------------------------------------------------------

# Same non-muscle exclusions as the group script (bones/vessels/nerves/tendons…).
EXCLUDE = [
    "ligament", "nerve", "vein", "artery", "vessel", "sulcus", "gyrus",
    "gland", "foramen", "duct", "bone", "fossa", "crest", "tubercle",
    "canal", "membrane", "cartilage", "bursa", "joint capsule", "meniscus",
    "node", "plexus", "septum", "process of", "notch", "line of",
    "tuberosity", "epicondyle", "condyle", "fissure", "sinus", "ventricle",
    "tendon",
]

# (head base name — side gets prefixed) -> Z-Anatomy name patterns (regex,
# matched against the lowercased object name). Order matters: first match wins,
# so put the more specific patterns earlier. Keep these names in lock-step with
# MuscleGroup.muscleHeads (Left/Right + base).
HEAD_RULES = [
    # Deltoid (Z-Anatomy: clavicular / acromial / spinal parts of deltoid)
    ("Anterior Deltoid",  [r"clavicular part of deltoid", r"anterior.*deltoid", r"deltoid.*clavicular"]),
    ("Lateral Deltoid",   [r"acromial part of deltoid", r"middle.*deltoid", r"lateral.*deltoid", r"deltoid.*acromial"]),
    ("Posterior Deltoid", [r"spinal part of deltoid", r"posterior.*deltoid", r"deltoid.*spinal"]),
    # Pectoralis major (clavicular = upper; sternocostal/abdominal = lower)
    ("Upper Chest", [r"clavicular.*pectoralis major", r"clavicular part of pectoralis", r"pectoralis major.*clavicular"]),
    ("Lower Chest", [r"sternocostal.*pectoralis", r"sternal.*pectoralis", r"abdominal part of pectoralis", r"pectoralis major.*sternocostal"]),
    # Biceps brachii (arm) — qualify with "brachii" so biceps femoris never matches
    ("Biceps Long Head",  [r"long head of biceps brachii", r"biceps brachii.*long head"]),
    ("Biceps Short Head", [r"short head of biceps brachii", r"biceps brachii.*short head"]),
    # Triceps brachii
    ("Triceps Long Head",    [r"long head of triceps brachii", r"triceps brachii.*long head"]),
    ("Triceps Lateral Head", [r"lateral head of triceps brachii", r"triceps brachii.*lateral head"]),
    ("Triceps Medial Head",  [r"medial head of triceps brachii", r"deep head of triceps", r"triceps brachii.*medial head"]),
    # Trapezius (descending = upper, transverse = middle, ascending = lower)
    ("Upper Trapezius",  [r"descending part of trapezius", r"superior.*trapezius", r"upper.*trapezius"]),
    ("Middle Trapezius", [r"transverse part of trapezius", r"middle.*trapezius"]),
    ("Lower Trapezius",  [r"ascending part of trapezius", r"inferior.*trapezius", r"lower.*trapezius"]),
    # Quadriceps (vastus intermedius is deep — folded into rectus femoris via omission)
    ("Rectus Femoris",   [r"rectus femoris"]),
    ("Vastus Lateralis", [r"vastus lateralis"]),
    ("Vastus Medialis",  [r"vastus medialis"]),
    # Hamstrings
    ("Biceps Femoris",   [r"biceps femoris"]),
    ("Semitendinosus",   [r"semitendinosus"]),
    ("Semimembranosus",  [r"semimembranosus"]),
    # Calves (gastrocnemius medial/lateral heads + soleus)
    ("Medial Gastrocnemius",  [r"medial head of gastrocnemius", r"medial.*gastrocnemius", r"gastrocnemius.*medial"]),
    ("Lateral Gastrocnemius", [r"lateral head of gastrocnemius", r"lateral.*gastrocnemius", r"gastrocnemius.*lateral"]),
    ("Soleus",                [r"soleus"]),
    # Glutes
    ("Gluteus Maximus", [r"gluteus maximus"]),
    ("Gluteus Medius",  [r"gluteus medius"]),
]

def side_of(name: str) -> str:
    # Trust only the unambiguous plain .l/.r suffix (see classify_hitboxes.py).
    low = name.lower().strip()
    m = re.search(r'\.([a-z0-9]+)$', low)
    if m:
        if m.group(1) == 'l':
            return 'l'
        if m.group(1) == 'r':
            return 'r'
    if low.endswith('(l)') or low.startswith('left '):
        return 'l'
    if low.endswith('(r)') or low.startswith('right '):
        return 'r'
    return ''

SIDE_WORD = {'l': 'Left', 'r': 'Right'}

matched = defaultdict(list)       # "Left Triceps Long Head" -> [(name, box), …]
unmatched_muscle_like = []

for name, box in d.items():
    low = name.lower()
    if any(x in low for x in EXCLUDE):
        continue
    side = side_of(name)
    if not side:
        continue
    head_base = None
    for base, patterns in HEAD_RULES:
        if any(re.search(p, low) for p in patterns):
            head_base = base
            break
    if head_base:
        matched[f"{SIDE_WORD[side]} {head_base}"].append((name, box))
    elif 'muscle' in low and 'head' in low:
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
