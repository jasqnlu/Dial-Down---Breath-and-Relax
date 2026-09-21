#!/usr/bin/env python3
"""fix_chunk.py <file> <index>=<lang>:<text> ...  — patch single translations (lang: es|fr|zh)."""
import json, sys
p = sys.argv[1]; t = json.load(open(p, encoding="utf-8"))
col = {"es": 0, "fr": 1, "zh": 2}
for a in sys.argv[2:]:
    i, rest = a.split("=", 1); lang, text = rest.split(":", 1)
    t[int(i)][col[lang]] = text
open(p, "w", encoding="utf-8").write("[\n" + ",\n".join(json.dumps(x, ensure_ascii=False) for x in t) + "\n]\n")
