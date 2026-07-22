"""
Shared muscle-classification rules for the Z-Anatomy -> app pipeline.

Single source of truth for the object-name -> MuscleGroup / sub-head mapping,
imported by:
  - classify_hitboxes.py       (unions each group into one AABB)
  - classify_head_hitboxes.py  (unions each sub-head into one AABB)
  - export_muscle_obj.py       (selects exactly these objects for the mesh
                                export + emits the node-name -> group map)

Keeping EXCLUDE / RULES / HEAD_RULES / side_of() in one place guarantees the
visual muscle mesh is built from *exactly* the objects the hitboxes were built
from, so every visible muscle chunk stays nameable and tappable.

Pure data + pure functions — no Blender, no I/O. Import and call.
"""

import re
from collections import defaultdict

# Z-Anatomy scene-organisation "helper" meshes that are NOT anatomy: category
# folder anchors (".g" suffix) and cross-section slicing planes. They carry
# huge synthetic bounding boxes that skew any whole-body recentre/scale, so
# they're excluded everywhere. (See extract_hitboxes.py for the full rationale.)
NON_ANATOMICAL = re.compile(r'\.g$|^Cross Section')

# Non-muscle structures to drop before bucketing. Superset of what both hitbox
# scripts historically used — classify_head_hitboxes.py omitted the last six
# (cornea/retina/... ), but none of those can ever match a HEAD_RULE, so folding
# them in is a proven no-op there while keeping one shared list.
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

# (MuscleGroup raw value) -> list of keyword patterns (lowercase substrings /
# regex). Each pattern is matched against the name with .l/.r or (L)/(R) suffix
# stripped separately (see side_of) to determine side. Keep in lock-step with
# MuscleGroup in Models/MuscleGroups.swift.
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

SIDE_WORD = {'l': 'Left', 'r': 'Right'}


def side_of(name: str) -> str:
    """Anatomical side ('l'/'r'/'') from a Z-Anatomy object name.

    Restrict to the UNAMBIGUOUS plain ".l"/".r" suffix only. Z-Anatomy's
    numbered/lettered variants (.ol, .er, .o1l, .e10r, …) are meant to be
    origin/insertion/segment markers, but some sit on the anatomically wrong
    side of the midline relative to their own suffix (e.g. "Short head of
    biceps brachii.ol" sits at x=+0.16 alongside the RIGHT-side cluster).
    Rather than out-guess an inconsistent third-party scheme, this only trusts
    the plain .l/.r suffix, which consistently marks each muscle's main belly.
    """
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


def is_excluded(name: str) -> bool:
    """True if `name` is a non-muscle structure (bone/vessel/nerve/tendon/…)."""
    return any(x in name.lower() for x in EXCLUDE)


def classify_group(name: str):
    """The MuscleGroup raw value for an object name, or None if unmatched.

    Mirrors classify_hitboxes.py's matching loop exactly: EXCLUDE filter, then
    the first RULES entry whose side (for Left/Right buckets) and any pattern
    match. Side-agnostic buckets (Abs, Head, …) ignore the suffix.
    """
    if is_excluded(name):
        return None
    low = name.lower()
    side = side_of(name)
    for group, patterns in RULES:
        if group.startswith("Left ") and side != 'l':
            continue
        if group.startswith("Right ") and side != 'r':
            continue
        for p in patterns:
            if re.search(p, low):
                return group
    return None


def classify_head(name: str):
    """The full sub-head name ("Left Triceps Long Head") for an object, or None.

    Mirrors classify_head_hitboxes.py: EXCLUDE filter, require a plain .l/.r
    side, then the first matching HEAD_RULE. Face zones live on the skin (no
    muscle geometry) and are intentionally out of scope here.
    """
    if is_excluded(name):
        return None
    side = side_of(name)
    if not side:
        return None
    low = name.lower()
    for base, patterns in HEAD_RULES:
        if any(re.search(p, low) for p in patterns):
            return f"{SIDE_WORD[side]} {base}"
    return None


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
    ("Hip",            [r"capsule of hip", r"iliofemoral", r"pubofemoral", r"ischiofemoral",
                        r"ligament of head of femur", r"zona orbicularis", r"acetabular"]),
]
_SPINE_LETTER = {"c": "Neck", "l": "Lower Spine"}


def _spine_region(low: str):
    """Neck/Lower Spine from a disc/nucleus level, bucketed by the FIRST
    vertebra letter (so cervical -> Neck, lumbar -> Lower Spine; thoracic
    has no bucket and returns None)."""
    m = re.search(r"(?:intervertebral disc|nucleus pulposus)\s+([ctl])\d", low)
    return _SPINE_LETTER.get(m.group(1)) if m else None


def classify_joint(name: str):
    """One of the 6 kept joint region names for a joint object, else None."""
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


def apply_recentre_correction(d: dict):
    """Second affine pass that recentres the extracted per-object AABBs onto the
    true whole-body midline, computed from trustworthy (non-.g / non-cross-
    section) objects only — mathematically equivalent to redoing the extract
    pipeline with those helpers excluded from the start.

    Returns (corrected_dict, center, scale, excluded_marker_count).
    """
    trusted = {n: b for n, b in d.items() if not NON_ANATOMICAL.search(n)}
    t_min = [min(b['min'][i] for b in trusted.values()) for i in range(3)]
    t_max = [max(b['max'][i] for b in trusted.values()) for i in range(3)]
    center = [(t_min[i] + t_max[i]) / 2 for i in range(3)]
    height = t_max[1] - t_min[1]
    scale = 2.0 / height if height > 0 else 1.0

    def recorrect(box):
        lo = [(box['min'][i] - center[i]) * scale for i in range(3)]
        hi = [(box['max'][i] - center[i]) * scale for i in range(3)]
        return {"min": lo, "max": hi}

    corrected = {n: recorrect(b) for n, b in trusted.items()}
    return corrected, center, scale, len(d) - len(trusted)
