#!/usr/bin/env python3
"""Write docs/l10n/EXERCISE_TRANSLATION_REVIEW.md — what a native-speaker reviewer needs.

  python3 Tools/l10n/report_exercise_review.py
"""
import json, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
src = json.loads((root / "Tools/l10n/exercise_source.json").read_text(encoding="utf-8"))
def load(prefix):
    rows = []
    for f in sorted((root / "Tools/l10n/chunks").glob(f"{prefix}*.json")):
        rows += json.loads(f.read_text(encoding="utf-8"))
    return rows
cautions = list(zip(src["cautions"], load("cautions")))
esc = lambda s: s.replace("|", "\\|")
out = ["# Exercise translation review", "",
"All exercise text in `Resources/Localized/exercises.<lang>.json` is a **machine draft**; every entry",
"carries `\"needsReview\": true`. The English text is always the fallback, so nothing is unsafe to ship",
"unreviewed — but the safety cautions below should be read by a fluent speaker before release.", "",
"## Scope", "",
f"| | Count |\n|---|---|\n| Exercises (per language) | 372 |\n| Unique names | {len(src['names'])} |",
f"| Unique instruction lines | {len(src['instructions'])} ({len(src['instructions_to_translate'])} translated, "
f"{len(src['instructions_derived'])} Left/Right twins derived by side-swap) |",
f"| Safety cautions | {len(src['cautions'])} |\n| Animation callouts | {len(src['callouts'])} |", "",
"## How to review", "",
"1. Edit the translation in `Tools/l10n/chunks/*.json` (index-aligned `[es, fr, zh-Hans]` per English line — see",
"   `Tools/l10n/exercise_source.json` for the numbered English).",
"2. `python3 Tools/l10n/check_chunk.py names|cautions|callouts|instr` — checks alignment, that every number is",
"   preserved, and that Left/Right words match the English.",
"3. `python3 Tools/l10n/assemble_exercise_overlays.py` regenerates the overlays (it resets `needsReview` to true;",
"   clear flags for reviewed languages once you have a sign-off process).",
"4. Unit tests (`ExerciseL10nTests`) enforce full coverage, instruction-count parity and number preservation.", "",
"## Conventions used", "",
"- Sides: es \"lado izquierdo/derecho\" or izquierdo/a; fr \"gauche/droite\" (gender-agreed); zh 左/右.",
"- fr avoids \"droit\" for *straight* (uses tendu/allongé) so it can never be confused with *right*.",
"- es uses tú, fr uses vous, zh has no pronoun. Counts: es \"tiempos\", fr \"temps\", zh 拍.",
"- Sanskrit terms (Ujjayi, Kapalabhati, Sitali…) are kept as-is.", "",
"## Safety cautions (highest priority)", "",
"| # | English | Español | Français | 简体中文 |", "|---|---|---|---|---|"]
for i, (en, (es, fr, zh)) in enumerate(cautions):
    out.append(f"| {i} | {esc(en)} | {esc(es)} | {esc(fr)} | {esc(zh)} |")
d = root / "docs/l10n"; d.mkdir(parents=True, exist_ok=True)
(d / "EXERCISE_TRANSLATION_REVIEW.md").write_text("\n".join(out) + "\n", encoding="utf-8")
print("wrote", d / "EXERCISE_TRANSLATION_REVIEW.md", len(out), "lines")
