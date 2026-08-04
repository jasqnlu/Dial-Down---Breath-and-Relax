"""Derive the 6-region joint hit boxes from REAL Z-Anatomy joint geometry
(capsules/ligaments/discs), replacing the hand-placed boxes.

Pipeline (same two-step shape as classify_hitboxes.py):
    1. In Blender: extract_hitboxes.py -> /tmp/body_part_hitboxes.json
    2. python3 Tools/blender/classify_joint_hitboxes.py
       -> Tools/blender/generated/joint_hitboxes.json
Buckets each joint object by classify_joint and unions each region into one AABB.
Same normalized model space as the muscle/head boxes (shared apply_recentre_
correction), so all boxes align with BodySkinMuscle.obj.
"""
import json
import os
from collections import defaultdict

from muscle_classification import classify_joint, apply_recentre_correction

SRC = "/tmp/body_part_hitboxes.json"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated")
OUT = os.path.join(OUT_DIR, "joint_hitboxes.json")


def bucket_joint_boxes(corrected: dict) -> dict:
    """{name: box} -> {joint region: unioned box}. Ignores non-kept joints."""
    matched = defaultdict(list)
    for name, box in corrected.items():
        region = classify_joint(name)
        if region:
            matched[region].append(box)
    final = {}
    for region, boxes in matched.items():
        final[region] = {
            "min": [min(b["min"][i] for b in boxes) for i in range(3)],
            "max": [max(b["max"][i] for b in boxes) for i in range(3)],
        }
    return final


if __name__ == "__main__":
    d = json.load(open(SRC))
    corrected, _c, _s, _n = apply_recentre_correction(d)
    final = bucket_joint_boxes(corrected)
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT, "w") as f:
        json.dump(final, f, indent=2)
    print(f"Wrote {len(final)} joint regions to {OUT}")
    for region in sorted(final):
        b = final[region]
        cx = (b["min"][0] + b["max"][0]) / 2
        print(f"  {region:22} center x={cx:+.3f}")
    expected = (["Neck", "Lower Spine"]
                + [f"{s} {j}" for s in ("Left", "Right")
                   for j in ("Shoulder Joint", "Hip")])
    missing = [r for r in expected if r not in final]
    print(f"\nMissing joint regions ({len(missing)}): {missing}")
