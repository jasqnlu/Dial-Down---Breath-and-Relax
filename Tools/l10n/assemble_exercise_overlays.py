#!/usr/bin/env python3
"""Build Resources/Localized/exercises.<lang>.json from SeedData.json + the reviewed
translation chunks in Tools/l10n/chunks/.

  python3 Tools/l10n/assemble_exercise_overlays.py

Every entry is written with "needsReview": true — machine drafts. A human reviewer
clears the flag by editing the overlay (or the chunk + re-running, then flipping it).
Left/Right twin instruction lines are derived from their translated twin by swapping the
side words (es: izquierd*/derech*, fr: gauche/droit(e) with noun gender, zh: 左/右).
The script fails loudly on any French noun it can't gender, rather than guessing.
"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
L10N = ROOT / "Tools/l10n"
SEED = ROOT / "Breath - Relax & Stretch/Resources/SeedData.json"
OUT = ROOT / "Breath - Relax & Stretch/Resources/Localized"
LANGS = [("es", 0, "es"), ("fr", 1, "fr"), ("zh-Hans", 2, "zh")]

src = json.loads((L10N / "exercise_source.json").read_text(encoding="utf-8"))

def load(prefix):
    rows = []
    for f in sorted((L10N / "chunks").glob(f"{prefix}*.json")):
        rows += json.loads(f.read_text(encoding="utf-8"))
    return rows

# ---- side swapping ---------------------------------------------------------
FR_FEM = {"jambe", "main", "narine", "cheville", "cuisse", "hanche", "épaule", "oreille", "fesse",
          "aine", "poitrine", "tempe", "gauche", "droite", "jambes", "mains", "hanches", "épaules",
          "narines", "cuisses", "chevilles", "fesses", "clavicule", "aisselle", "plante", "voûte", "paume", "paumes"}
FR_MASC = {"genou", "pied", "bras", "coude", "poignet", "pouce", "orteil", "talon", "mollet", "côté",
           "œil", "cou", "doigt", "tibia", "buste", "membre", "biceps", "triceps", "genoux", "pieds",
           "coudes", "poignets", "orteils", "talons", "mollets", "doigts", "avant-bras", "haut", "bas",
           "dos", "grand dorsal", "dorsal", "quadriceps", "trapèze", "sourcil", "index", "majeur", "arrière", "avant"}
FR_ADV = {"à", "la", "vers", "sur", "de", "le", "l'"}   # "à gauche", "la gauche", "vers la gauche"

def swap_es(t):
    def r(m):
        stem, end = m.group(1).lower(), m.group(2)
        return ("derech" if stem.startswith("izq") else "izquierd") + end
    return re.sub(r"\b(izquierd|derech)(os|as|o|a)\b", r, t, flags=re.I)

def swap_zh(t):
    if "左右" in t:
        raise ValueError("zh twin contains 左右: " + t)
    return t.translate({ord("左"): "右", ord("右"): "左"})

def swap_fr(t):
    def r(m):
        w = m.group(0); low = w.lower()
        if low.startswith("gauche"):
            plural = "s" if low.endswith("s") else ""
            before = re.findall(r"([\wÀ-ÿ'’-]+)\s*$", t[:m.start()])
            prev_full = re.sub(r"^(?:l|d|qu)['’]", "", before[0].lower()) if before else ""
            prev = prev_full.rstrip("s")
            if prev_full in FR_ADV or prev in FR_ADV:
                return "droite" + plural
            if prev_full in FR_FEM or prev in FR_FEM:
                return "droite" + plural
            if prev_full in FR_MASC or prev in FR_MASC:
                return "droit" + plural
            raise ValueError(f"fr gender unknown before 'gauche' ({prev_full!r}): {t}")
        return "gauche" + ("s" if low.endswith("s") else "")
    return re.sub(r"\b(gauches?|droites?s?|droits?)\b", r, t, flags=re.I)

SWAP = {"es": swap_es, "fr": swap_fr, "zh": swap_zh}

# ---- build lookup tables ---------------------------------------------------
names = dict(zip(src["names"], load("names")))
cautions = dict(zip(src["cautions"], load("cautions")))
callouts = dict(zip(src["callouts"], load("callouts")))
instr = dict(zip(src["instructions_to_translate"], load("instr")))
assert len(names) == len(src["names"]) and len(instr) == len(src["instructions_to_translate"])

unknown = {}
for line, twin in src["instructions_derived"].items():   # `line` derived from `twin`
    base = instr[twin]
    try:
        instr[line] = [SWAP[code](base[i]) for i, (_, _, code) in enumerate(LANGS)]
    except ValueError as err:
        unknown[str(err)] = line
if unknown:
    print("Cannot derive", len(unknown), "twin lines — extend FR_FEM/FR_MASC:")
    for msg in sorted(unknown): print("  ", msg[:150])
    sys.exit(1)

# ---- write overlays --------------------------------------------------------
seed = json.loads(SEED.read_text(encoding="utf-8"))["exercises"]
OUT.mkdir(parents=True, exist_ok=True)
for lang, idx, _ in LANGS:
    entries = {}
    for e in seed:
        entry = {"name": names[e["name"]][idx],
                 "instructions": [instr[i][idx] for i in e.get("instructions", [])],
                 "needsReview": True}
        if e.get("caution"): entry["caution"] = cautions[e["caution"]][idx]
        c = e.get("animationCallout")
        if c and c.get("text"): entry["callout"] = callouts[c["text"]][idx]
        entries[e["id"].lower()] = entry
    (OUT / f"exercises.{lang}.json").write_text(
        json.dumps({"language": lang, "exercises": entries}, ensure_ascii=False, indent=1, sort_keys=True) + "\n",
        encoding="utf-8")
    print(f"{lang}: {len(entries)} exercises")
