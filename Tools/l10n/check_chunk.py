#!/usr/bin/env python3
"""check_chunk.py <names|cautions|callouts|instr>: validate chunk files (index-aligned,
3 languages each, digits preserved) against exercise_source.json."""
import json, re, sys, pathlib
root = pathlib.Path(__file__).resolve().parent
cat = sys.argv[1]
src = json.loads((root / "exercise_source.json").read_text(encoding="utf-8"))
files = sorted(root.glob(f"chunks/{cat}*.json"))
tr = []
for f in files:
    tr += json.loads(f.read_text(encoding="utf-8"))
en = src["instructions_to_translate"] if cat == "instr" else src[cat]
digits = lambda t: re.findall(r"\d+", t)
print(cat, "english:", len(en), "translated:", len(tr))
bad = 0
for i, (e, t) in enumerate(zip(en, tr)):
    if len(t) != 3 or any(not x.strip() for x in t):
        print("  shape", i, e[:50]); bad += 1; continue
    for lang, x in zip(("es", "fr", "zh"), t):
        if digits(e) != digits(x):
            print(f"  digits {lang} #{i}: {e[:60]!r} -> {x[:60]!r}"); bad += 1
    # Left/Right twins are derived by swapping side words, so every translation
    # must carry exactly as many side words as the English ("左右" = "side to side").
    n = len(re.findall(r"\b(?:left|right)\b", e, re.I))
    counts = {"es": len(re.findall(r"izquierd|derech", t[0])),
              "fr": len(re.findall(r"\b(?:gauches?|droite?s?)\b", t[1])),
              "zh": len(re.findall(r"[左右]", t[2].replace("左右", "")))}
    for lang, c in counts.items():
        if c != n:
            print(f"  sides {lang} #{i} ({c} vs {n}): {e[:70]!r}"); bad += 1
print("problems:", bad)
