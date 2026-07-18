#!/usr/bin/env python3
"""One-off: swap 'Left *' <-> 'Right *' keys in musclegroup_hitboxes.json.

The committed JSON followed the app's OLD screen-side ('mirror') convention
(Left = negative-x = viewer's left at front view). The 3D marking redesign
(docs/superpowers/specs/2026-07-15-3d-muscle-tap-marking-design.md) uses
anatomical naming: Left = the figure's own left = positive-x.
"""
import json
import pathlib

path = pathlib.Path(__file__).parent / "musclegroup_hitboxes.json"
src = json.loads(path.read_text())


def swap(name):
    if name.startswith("Left "):
        return "Right " + name[5:]
    if name.startswith("Right "):
        return "Left " + name[6:]
    return name


out = {swap(k): v for k, v in src.items()}
assert len(out) == len(src)
# sanity: every "Left *" entry must now sit on positive-x
for k, v in out.items():
    cx = (v["min"][0] + v["max"][0]) / 2
    if k.startswith("Left "):
        assert cx > 0, (k, cx)
    if k.startswith("Right "):
        assert cx < 0, (k, cx)
path.write_text(json.dumps(out, indent=2))
print(f"Swapped L/R keys for {len(out)} entries.")
