#!/usr/bin/env python3
"""Extract the unique English exercise strings that need translating.

Writes Tools/l10n/exercise_source.json:
  {"names": [...], "instructions": [...], "cautions": [...], "callouts": [...]}
Lists are de-duplicated and sorted, so chunk files (which are index-aligned to
these lists) stay valid until the seed data changes. Re-run and re-check the
chunk files if SeedData.json changes.
"""
import json, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
seed = json.loads((root / "Breath - Relax & Stretch/Resources/SeedData.json").read_text(encoding="utf-8"))["exercises"]
names, instr, cautions, callouts = set(), set(), set(), set()
for e in seed:
    names.add(e["name"])
    instr.update(e.get("instructions", []))
    if e.get("caution"): cautions.add(e["caution"])
    c = e.get("animationCallout")
    if c and c.get("text"): callouts.add(c["text"])
out = {k: sorted(v) for k, v in
       (("names", names), ("instructions", instr), ("cautions", cautions), ("callouts", callouts))}

# Left/Right twins: a line whose left<->right swap is also in the list is
# derived from its twin at assembly time (the lexicographically smaller line,
# i.e. the one that says "left" first, is the one that gets translated).
import re as _re
def swap_sides(t):
    return _re.sub(r"\b(left|right)\b",
                   lambda m: {"left": "right", "right": "left"}[m.group(1).lower()]
                             if m.group(1).islower() else {"Left": "Right", "Right": "Left"}[m.group(1)], t, flags=_re.I)
present = set(out["instructions"])
derived, to_translate = {}, []
for line in out["instructions"]:
    twin = swap_sides(line)
    if twin != line and twin in present and twin < line:
        derived[line] = twin          # `line` is derived from `twin`
    else:
        to_translate.append(line)
out["instructions_to_translate"] = to_translate
out["instructions_derived"] = derived
(root / "Tools/l10n/exercise_source.json").write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
print({k: len(v) for k, v in out.items()})
