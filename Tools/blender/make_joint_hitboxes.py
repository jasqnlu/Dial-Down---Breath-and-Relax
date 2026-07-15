#!/usr/bin/env python3
"""Derive joint hit boxes from adjacent muscle-group boxes.

Each joint straddles the y-gap between its upper and lower neighbor groups;
x/z cover the neighbors' union. Same normalized model space as
musclegroup_hitboxes.json. Verify visually with -debugHitboxes YES.
"""
import json
import pathlib

here = pathlib.Path(__file__).parent
src = json.loads((here / "musclegroup_hitboxes.json").read_text())


def joint(uppers, lowers, half_h, xz_from=None):
    """xz_from: names whose x/z union bounds the joint (defaults to all
    neighbors). Keep it tight — the joint box must have the SMALLEST volume
    of any box containing its own center, or MuscleHitResolver's
    smallest-volume tiebreak hands the tap to a muscle instead."""
    boxes = [src[n] for n in xz_from or (uppers + lowers)]
    u_bottom = min(src[n]["min"][1] for n in uppers)
    l_top = max(src[n]["max"][1] for n in lowers)
    yc = (u_bottom + l_top) / 2
    return {
        "min": [min(b["min"][0] for b in boxes), yc - half_h, min(b["min"][2] for b in boxes)],
        "max": [max(b["max"][0] for b in boxes), yc + half_h, max(b["max"][2] for b in boxes)],
    }


out = {}
for side in ("Left", "Right"):
    # Elbow/ankle x/z stay tight to one neighbor: the union span made them
    # bigger than the biceps/foot boxes that also contain their centers.
    out[f"{side} Elbow"] = joint([f"{side} Biceps", f"{side} Triceps"], [f"{side} Forearm"],
                                 0.035, xz_from=[f"{side} Biceps"])
    out[f"{side} Wrist"] = joint([f"{side} Forearm"], [f"{side} Hand"], 0.025)
    out[f"{side} Knee"] = joint([f"{side} Quadriceps", f"{side} Hamstrings"],
                                [f"{side} Calves", f"{side} Tibialis"], 0.045)
    out[f"{side} Ankle"] = joint([f"{side} Calves", f"{side} Tibialis"], [f"{side} Foot"],
                                 0.020, xz_from=[f"{side} Foot"])

(here / "joint_hitboxes.json").write_text(json.dumps(out, indent=2))
print(f"Wrote {len(out)} joint boxes.")
