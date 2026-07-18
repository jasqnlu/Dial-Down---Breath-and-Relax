import json, re
from collections import defaultdict

d = json.load(open("/tmp/body_part_hitboxes.json"))

# --- Correct a bad whole-body recentering pivot -----------------------------
# extract_hitboxes.py computed its recentre/scale from EVERY mesh object,
# including 14 non-anatomical Z-Anatomy scene-organisation helpers: category
# folder anchors ("Joints.g", "Muscular system.g", ...) and cross-section
# slicing planes ("Cross Section X/Y/Z"). Those have deliberately huge,
# synthetic bounding boxes (e.g. x down to -0.757, y pinned to exactly -1.0/
# +1.0) that don't correspond to any real body geometry, so they dragged the
# computed centre off the true left-right midline — every muscle, left AND
# right, ended up on the same (positive-x) side after recentring.
#
# Since the original recentre+scale was a single uniform affine transform
# applied identically to every object, we can correct it with a second
# affine pass computed from trustworthy objects only — mathematically
# equivalent to redoing the whole pipeline with those 14 objects excluded
# from the start, without needing to re-run Blender.
NON_ANATOMICAL = re.compile(r'\.g$|^Cross Section')
trusted = {n: b for n, b in d.items() if not NON_ANATOMICAL.search(n)}
excluded_markers = len(d) - len(trusted)

t_min = [min(b['min'][i] for b in trusted.values()) for i in range(3)]
t_max = [max(b['max'][i] for b in trusted.values()) for i in range(3)]
correction_center = [(t_min[i] + t_max[i]) / 2 for i in range(3)]
correction_height = t_max[1] - t_min[1]
correction_scale = 2.0 / correction_height if correction_height > 0 else 1.0

print(f"Excluded {excluded_markers} non-anatomical scene-organisation objects "
      f"(category folders, cross-section planes) from the recentering fix")
print(f"Corrected centre: {[round(c, 3) for c in correction_center]}, "
      f"rescale factor: {correction_scale:.4f}\n")

def recorrect(box):
    lo = [(box['min'][i] - correction_center[i]) * correction_scale for i in range(3)]
    hi = [(box['max'][i] - correction_center[i]) * correction_scale for i in range(3)]
    return {"min": lo, "max": hi}

d = {n: recorrect(b) for n, b in trusted.items()}
# --- end correction -----------------------------------------------------

EXCLUDE = [
    "ligament", "nerve", "vein", "artery", "vessel", "sulcus", "gyrus",
    "gland", "foramen", "duct", "bone", "fossa", "crest", "tubercle",
    "canal", "membrane", "cartilage", "bursa", "joint capsule", "meniscus",
    "node", "plexus", "septum", "process of", "notch", "line of",
    "tuberosity", "epicondyle", "condyle", "fissure", "sinus", "ventricle",
    "cornea", "retina", "cochlea", "tooth", "teeth", "gingiva",
    "tendon",  # tendon sheaths, not the muscle belly itself — often span
               # far from the actual muscle (e.g. a wrist tendon sheath
               # reaching down toward the fingertips).
]

# (MuscleGroup raw value) -> list of keyword patterns (lowercase substrings).
# Each pattern is matched against the name with .l/.r or (L)/(R) suffix
# stripped separately to determine side.
RULES = [
    ("Front Neck", ["sternocleidomastoid", "scalenus", "longus colli", "longus capitis", "infrahyoid", "suprahyoid", "omohyoid", "sternohyoid", "sternothyroid", "thyrohyoid", "digastric", "mylohyoid", "geniohyoid", "platysma"]),
    ("Back Neck", ["splenius capitis", "splenius cervicis", "semispinalis capitis", "semispinalis cervicis", "longissimus capitis", "longissimus cervicis", "rectus capitis", "obliquus capitis", "multifidus cervicis"]),
    ("Left Trapezius", ["trapezius"]),  # side handled by suffix
    ("Right Trapezius", ["trapezius"]),
    ("Left Shoulder", ["deltoid muscle", "deltoideus", "supraspinatus", "infraspinatus", "teres minor", "teres major", "subscapularis", "rotator cuff"]),
    ("Right Shoulder", ["deltoid muscle", "deltoideus", "supraspinatus", "infraspinatus", "teres minor", "teres major", "subscapularis", "rotator cuff"]),
    ("Left Chest", ["pectoralis major", "pectoralis minor", "serratus anterior"]),
    ("Right Chest", ["pectoralis major", "pectoralis minor", "serratus anterior"]),
    ("Abs", ["rectus abdominis", "transversus abdominis", "pyramidalis"]),
    ("Left Obliques", ["external abdominal oblique", "internal abdominal oblique"]),
    ("Right Obliques", ["external abdominal oblique", "internal abdominal oblique"]),
    ("Left Lats", ["latissimus dorsi"]),
    ("Right Lats", ["latissimus dorsi"]),
    ("Spinal Erectors", ["erector spinae", "iliocostalis", "longissimus thoracis", "spinalis", "multifidus thoracis", "multifidus lumborum", "semispinalis thoracis"]),
    ("Lower Back", ["quadratus lumborum", "multifidus lumborum"]),
    ("Left Biceps", ["biceps brachii", "brachialis", "coracobrachialis"]),
    ("Right Biceps", ["biceps brachii", "brachialis", "coracobrachialis"]),
    ("Left Triceps", ["triceps brachii", "anconeus"]),
    ("Right Triceps", ["triceps brachii", "anconeus"]),
    # "digitorum"/"pollicis" names are reused for foot muscles too (extensor/
    # flexor digitorum BREVIS/LONGUS live in the foot or shin, not forearm),
    # so these must be qualified rather than bare substrings — a bare
    # "extensor digitorum" would also match "Extensor digitorum longus"
    # (a shin muscle, correctly bucketed under Tibialis below).
    ("Left Forearm", ["flexor carpi", "extensor carpi", r"flexor digitorum superficialis", r"flexor digitorum profundus", r"extensor digitorum(?!\s+(brevis|longus))", "pronator", "supinator", "palmaris longus", "brachioradialis", "flexor pollicis longus", "extensor pollicis"]),
    ("Right Forearm", ["flexor carpi", "extensor carpi", r"flexor digitorum superficialis", r"flexor digitorum profundus", r"extensor digitorum(?!\s+(brevis|longus))", "pronator", "supinator", "palmaris longus", "brachioradialis", "flexor pollicis longus", "extensor pollicis"]),
    ("Left Glutes", ["gluteus maximus", "gluteus medius", "gluteus minimus", "piriformis"]),
    ("Right Glutes", ["gluteus maximus", "gluteus medius", "gluteus minimus", "piriformis"]),
    ("Left Hip Flexors", ["iliopsoas", "psoas major", "psoas minor", "iliacus", "sartorius", "tensor fasciae latae", "pectineus"]),
    ("Right Hip Flexors", ["iliopsoas", "psoas major", "psoas minor", "iliacus", "sartorius", "tensor fasciae latae", "pectineus"]),
    ("Left Adductors", ["adductor longus", "adductor brevis", "adductor magnus", "adductor minimus", "gracilis"]),
    ("Right Adductors", ["adductor longus", "adductor brevis", "adductor magnus", "adductor minimus", "gracilis"]),
    ("Left Quadriceps", ["quadriceps femoris", "rectus femoris", "vastus lateralis", "vastus medialis", "vastus intermedius"]),
    ("Right Quadriceps", ["quadriceps femoris", "rectus femoris", "vastus lateralis", "vastus medialis", "vastus intermedius"]),
    ("Left Hamstrings", ["biceps femoris", "semitendinosus", "semimembranosus"]),
    ("Right Hamstrings", ["biceps femoris", "semitendinosus", "semimembranosus"]),
    # flexor digitorum/hallucis LONGUS bellies sit in the deep posterior
    # lower leg (with gastrocnemius/soleus), even though their tendons run
    # into the foot — distinct from the foot-intrinsic BREVIS versions below.
    ("Left Calves", ["gastrocnemius", "soleus", "plantaris", "flexor digitorum longus", "flexor hallucis longus"]),
    ("Right Calves", ["gastrocnemius", "soleus", "plantaris", "flexor digitorum longus", "flexor hallucis longus"]),
    ("Left Tibialis", ["tibialis anterior", "tibialis posterior", "extensor digitorum longus", "extensor hallucis longus", "peroneus", "fibularis"]),
    ("Right Tibialis", ["tibialis anterior", "tibialis posterior", "extensor digitorum longus", "extensor hallucis longus", "peroneus", "fibularis"]),
    ("Head", ["temporalis", "masseter", "frontalis", "occipitalis", "orbicularis oculi", "orbicularis oris", "buccinator", "zygomaticus"]),
    # "opponens digiti minimi" alone matches BOTH the hand and foot muscles
    # of that name — must qualify with "of hand" (foot's counterpart is
    # qualified "of foot" below).
    ("Left Hand", ["interosseus manus", "lumbrical.*manus", "opponens pollicis", "opponens digiti minimi muscle of hand", "abductor pollicis", "abductor digiti minimi manus", "flexor pollicis brevis"]),
    ("Right Hand", ["interosseus manus", "lumbrical.*manus", "opponens pollicis", "opponens digiti minimi muscle of hand", "abductor pollicis", "abductor digiti minimi manus", "flexor pollicis brevis"]),
    ("Left Foot", ["flexor digitorum brevis", "abductor hallucis", "abductor digiti minimi pedis", "quadratus plantae", "interosseus pedis", "extensor digitorum brevis", "flexor hallucis brevis", "adductor hallucis", "extensor hallucis brevis", "opponens digiti minimi muscle of foot"]),
    ("Right Foot", ["flexor digitorum brevis", "abductor hallucis", "abductor digiti minimi pedis", "quadratus plantae", "interosseus pedis", "extensor digitorum brevis", "flexor hallucis brevis", "adductor hallucis", "extensor hallucis brevis", "opponens digiti minimi muscle of foot"]),
]

def side_of(name: str) -> str:
    # Restrict to the UNAMBIGUOUS plain ".l"/".r" suffix only. Z-Anatomy's
    # numbered/lettered variants (.ol, .er, .o1l, .e10r, ...) are meant to be
    # origin/insertion/segment markers, but some of them sit on the
    # anatomically wrong side of the midline relative to their own suffix
    # (confirmed empirically, e.g. "Short head of biceps brachii.ol" sits at
    # x=+0.16 alongside the RIGHT-side cluster, not the left). Rather than
    # trying to out-guess an inconsistent third-party naming scheme, this
    # only trusts the plain .l/.r suffix, which consistently corresponds to
    # each muscle's main belly object.
    low = name.lower().strip()
    m = re.search(r'\.([a-z0-9]+)$', low)
    if m:
        token = m.group(1)
        if token == 'l':
            return 'l'
        if token == 'r':
            return 'r'
    if low.endswith('(l)') or ' left ' in f' {low} ' or low.startswith('left '):
        return 'l'
    if low.endswith('(r)') or ' right ' in f' {low} ' or low.startswith('right '):
        return 'r'
    return ''

matched = defaultdict(list)   # MuscleGroup raw value -> list of (name, box)
unmatched_muscle_like = []
excluded_count = 0

for name, box in d.items():
    low = name.lower()
    if any(x in low for x in EXCLUDE):
        excluded_count += 1
        continue
    side = side_of(name)
    hit_group = None
    for group, patterns in RULES:
        is_left_group = group.startswith("Left ")
        is_right_group = group.startswith("Right ")
        if is_left_group and side != 'l':
            continue
        if is_right_group and side != 'r':
            continue
        for p in patterns:
            if re.search(p, low):
                hit_group = group
                break
        if hit_group:
            break

    if hit_group:
        matched[hit_group].append((name, box))
    else:
        # Stricter signal than before: the literal word "muscle" in the name
        # is a solid indicator this is skeletal muscle we failed to bucket
        # (as opposed to bone/vessel/nerve names that happen to end in a
        # Latin-looking suffix, which produced too many false positives).
        if 'muscle' in low:
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
# model's own left/right) — and since the 3D marking redesign
# (docs/superpowers/specs/2026-07-15-3d-muscle-tap-marking-design.md) the app
# uses the SAME anatomical convention: "Left Biceps" is the figure's own left
# arm (world +X, since the model faces +Z) at every camera angle. The old 2D
# body map used screen-side ("mirror") naming and this function used to swap
# sides to match it; that swap is deliberately gone. Do not reintroduce it —
# HitboxDataTests pins Left = positive-x.
def app_side_swap(group_name: str) -> str:
    return group_name

final = {}
for group, items in matched.items():
    mins = [b['min'] for _, b in items]
    maxs = [b['max'] for _, b in items]
    lo = [min(m[i] for m in mins) for i in range(3)]
    hi = [max(m[i] for m in maxs) for i in range(3)]
    final[app_side_swap(group)] = {"min": lo, "max": hi, "source_object_count": len(items)}

with open("/tmp/musclegroup_hitboxes.json", "w") as f:
    json.dump(final, f, indent=2)
print()
print(f"Wrote {len(final)}-group unioned hitboxes to /tmp/musclegroup_hitboxes.json")

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
