"""Verify the staged skin+muscle assets (no Blender needed):
    python3 Tools/blender/verify_skin_muscle_export.py
Checks coverage, no excluded-system leakage, mesh<->hitbox alignment, L=+x.
Adapted from verify_anatomy_export.py for the skin-covered pivot: the skin
layer has exactly one node (BodySkin, no region box — it spans the whole
body), muscles are unchanged, and joints are hitbox-only (no geometry, so no
node-map coverage check for them — only the box set is checked)."""
import json, os, sys

GEN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated")

MUSCLE_GROUPS = {  # MuscleGroup.allCases raw values
    "Front Neck","Back Neck","Left Trapezius","Right Trapezius","Left Shoulder","Right Shoulder",
    "Left Chest","Right Chest","Abs","Left Obliques","Right Obliques","Left Lats","Right Lats",
    "Spinal Erectors","Lower Back","Left Biceps","Right Biceps","Left Triceps","Right Triceps",
    "Left Forearm","Right Forearm","Left Glutes","Right Glutes","Left Hip Flexors","Right Hip Flexors",
    "Left Adductors","Right Adductors","Left Quadriceps","Right Quadriceps","Left Hamstrings",
    "Right Hamstrings","Left Calves","Right Calves","Left Tibialis","Right Tibialis","Head",
    "Left Hand","Right Hand","Left Foot","Right Foot",
}
FACE_ZONES = {"Left Eye","Right Eye","Left Temple","Right Temple","Left Jaw","Right Jaw","Forehead"}  # MuscleGroup.headZones (Models/MuscleGroups.swift)
# JointRegion vocabulary, curated to 6 hitbox-only regions (Task 1 of the
# skin-covered pivot plan; keep in sync with Models/JointRegion.swift).
JOINT_REGIONS = {"Neck", "Lower Spine"} | {
    f"{s} {j}" for s in ("Left", "Right") for j in ("Shoulder Joint", "Hip")}
LEAK = ("bone","nerve","vein","artery","node","cochlea","tooth","teeth","ventricle","gland")


def load(name):
    return json.load(open(os.path.join(GEN, name)))


def parse_obj_centroids(path):
    """node name -> (cx,cy,cz) centroid of its vertices."""
    cur, acc = None, {}
    for line in open(path):
        if line.startswith("o "):
            cur = line[2:].strip()
            # setdefault (not reassign): if the OBJ ever splits one node across
            # multiple `o` blocks, accumulate all its vertices rather than
            # silently keeping only the last block's.
            acc.setdefault(cur, [0.0, 0.0, 0.0, 0])
        elif line.startswith("v ") and cur:
            _, x, y, z = line.split()[:4]
            a = acc[cur]; a[0]+=float(x); a[1]+=float(y); a[2]+=float(z); a[3]+=1
    return {n: (a[0]/a[3], a[1]/a[3], a[2]/a[3]) for n, a in acc.items() if a[3]}


def inside(box, p, eps=0.02):
    return all(box["min"][i]-eps <= p[i] <= box["max"][i]+eps for i in range(3))


def main():
    nodes = load("skinmuscle_node_names.json")["nodes"]
    groups = load("musclegroup_hitboxes.json")
    heads = load("musclegroup_head_hitboxes.json")
    joints = load("joint_hitboxes.json")
    centroids = parse_obj_centroids(os.path.join(GEN, "BodySkinMuscle.obj"))

    # 1. OBJ <-> node map are the same set.
    assert set(centroids) == set(nodes), (
        f"OBJ nodes != map nodes; only-in-obj={set(centroids)-set(nodes)}, "
        f"only-in-map={set(nodes)-set(centroids)}")

    # 2. No excluded-system leakage in any node name.
    for n in nodes:
        low = n.lower()
        assert not any(k in low for k in LEAK), f"leaked excluded structure: {n}"

    # 3. Skin layer has exactly one node.
    skin_nodes = [n for n, e in nodes.items() if e.get("layer") == "skin"]
    assert len(skin_nodes) == 1, f"expected exactly 1 skin node, found {skin_nodes}"

    # 4. Coverage: every muscle group / face zone has >=1 muscle node AND >=1 box.
    #    Joints are hitbox-only (no geometry/node-map entries) — only the box
    #    set is checked, against the 6 curated regions.
    muscle_entries = {n: e for n, e in nodes.items() if e.get("layer") == "muscle"}
    covered_groups = {e.get("group") for e in muscle_entries.values() if e.get("group")}
    covered_zones = {e.get("faceZone") for e in muscle_entries.values() if e.get("faceZone")}
    assert MUSCLE_GROUPS <= covered_groups, f"groups w/o node: {MUSCLE_GROUPS-covered_groups}"
    assert FACE_ZONES <= covered_zones, f"zones w/o node: {FACE_ZONES-covered_zones}"
    assert MUSCLE_GROUPS <= set(groups), f"groups w/o box: {MUSCLE_GROUPS-set(groups)}"
    assert FACE_ZONES <= set(heads), f"zones w/o box: {FACE_ZONES-set(heads)}"
    assert JOINT_REGIONS == set(joints), f"joint box set != expected: {set(joints)^JOINT_REGIONS}"

    # 5. L=+x / R=-x for every sided box.
    for coll in (groups, heads, joints):
        for name, box in coll.items():
            cx = (box["min"][0] + box["max"][0]) / 2
            if name.startswith("Left "):  assert cx > 0, f"{name} L but x={cx:.3f}"
            if name.startswith("Right "): assert cx < 0, f"{name} R but x={cx:.3f}"

    # 6. Alignment: each MUSCLE node centroid lies inside its region's box.
    #    The skin node is skipped — it spans the whole body, not one region.
    def box_for(entry):
        if entry.get("faceZone"): return heads.get(entry["faceZone"])
        if entry.get("head"): return heads.get(entry["head"])
        if entry.get("group"): return groups.get(entry["group"])
        return None
    misaligned = []
    for node, entry in muscle_entries.items():
        box = box_for(entry)
        if box and not inside(box, centroids[node]):
            misaligned.append(node)
    assert not misaligned, f"{len(misaligned)} nodes outside their box, e.g. {misaligned[:5]}"

    print(f"OK: {len(nodes)} nodes ({len(skin_nodes)} skin + {len(muscle_entries)} muscle), "
          f"{len(groups)} groups, {len(heads)} head/zone boxes, {len(joints)} joint boxes verified")


if __name__ == "__main__":
    if not __debug__:
        # Every gate below is an `assert`; under `python3 -O` they are stripped
        # and this harness would rubber-stamp any export. Refuse to run.
        sys.exit("verify_skin_muscle_export.py requires assertions (do not run with -O)")
    try:
        main()
    except AssertionError as e:
        print("VERIFY FAILED:", e); sys.exit(1)
