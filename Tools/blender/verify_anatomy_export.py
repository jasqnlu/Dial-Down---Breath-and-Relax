"""Verify the staged anatomy assets (no Blender needed):
    python3 Tools/blender/verify_anatomy_export.py
Checks coverage, no excluded-system leakage, mesh<->hitbox alignment, L=+x."""
import json, os, re, sys

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
FACE_ZONES = {"Left Eye","Right Eye","Left Temple","Right Temple","Left Jaw","Right Jaw","Forehead"}
JOINT_REGIONS = {"Neck","Upper Spine","Lower Spine"} | {
    f"{s} {j}" for s in ("Left","Right")
    for j in ("Shoulder Joint","Elbow","Wrist","Hip","Knee","Ankle")}
LEAK = ("bone","nerve","vein","artery","node","cochlea","tooth","teeth","ventricle","gland")


def load(name):
    return json.load(open(os.path.join(GEN, name)))


def parse_obj_centroids(path):
    """node name -> (cx,cy,cz) centroid of its vertices."""
    cur, acc = None, {}
    for line in open(path):
        if line.startswith("o "):
            cur = line[2:].strip()
            acc[cur] = [0.0, 0.0, 0.0, 0]
        elif line.startswith("v ") and cur:
            _, x, y, z = line.split()[:4]
            a = acc[cur]; a[0]+=float(x); a[1]+=float(y); a[2]+=float(z); a[3]+=1
    return {n: (a[0]/a[3], a[1]/a[3], a[2]/a[3]) for n, a in acc.items() if a[3]}


def inside(box, p, eps=0.02):
    return all(box["min"][i]-eps <= p[i] <= box["max"][i]+eps for i in range(3))


def main():
    nodes = load("anatomy_node_names.json")["nodes"]
    groups = load("musclegroup_hitboxes.json")
    heads = load("musclegroup_head_hitboxes.json")
    joints = load("joint_hitboxes.json")
    centroids = parse_obj_centroids(os.path.join(GEN, "BodyAnatomy.obj"))

    # 1. OBJ <-> node map are the same set.
    assert set(centroids) == set(nodes), (
        f"OBJ nodes != map nodes; only-in-obj={set(centroids)-set(nodes)}, "
        f"only-in-map={set(nodes)-set(centroids)}")

    # 2. No excluded-system leakage in any node name.
    for n in nodes:
        low = n.lower()
        assert not any(k in low for k in LEAK), f"leaked excluded structure: {n}"

    # 3. Coverage: every group / face zone / joint region has >=1 node AND >=1 box.
    covered_groups = {e.get("group") for e in nodes.values() if e.get("group")}
    covered_zones = {e.get("faceZone") for e in nodes.values() if e.get("faceZone")}
    covered_joints = {e.get("joint") for e in nodes.values() if e.get("joint")}
    assert MUSCLE_GROUPS <= covered_groups, f"groups w/o node: {MUSCLE_GROUPS-covered_groups}"
    assert FACE_ZONES <= covered_zones, f"zones w/o node: {FACE_ZONES-covered_zones}"
    assert JOINT_REGIONS <= covered_joints, f"joints w/o node: {JOINT_REGIONS-covered_joints}"
    assert MUSCLE_GROUPS <= set(groups), f"groups w/o box: {MUSCLE_GROUPS-set(groups)}"
    assert FACE_ZONES <= set(heads), f"zones w/o box: {FACE_ZONES-set(heads)}"
    assert JOINT_REGIONS == set(joints), f"joint box set != expected: {set(joints)^JOINT_REGIONS}"

    # 4. L=+x / R=-x for every sided box.
    for coll in (groups, heads, joints):
        for name, box in coll.items():
            cx = (box["min"][0] + box["max"][0]) / 2
            if name.startswith("Left "):  assert cx > 0, f"{name} L but x={cx:.3f}"
            if name.startswith("Right "): assert cx < 0, f"{name} R but x={cx:.3f}"

    # 5. Alignment: each node centroid lies inside its region's box.
    def box_for(entry):
        if entry.get("joint"): return joints.get(entry["joint"])
        if entry.get("faceZone"): return heads.get(entry["faceZone"])
        if entry.get("head"): return heads.get(entry["head"])
        if entry.get("group"): return groups.get(entry["group"])
        return None  # headSkin has no region box
    misaligned = []
    for node, entry in nodes.items():
        box = box_for(entry)
        if box and not inside(box, centroids[node]):
            misaligned.append(node)
    assert not misaligned, f"{len(misaligned)} nodes outside their box, e.g. {misaligned[:5]}"

    print(f"OK: {len(nodes)} nodes, {len(groups)} groups, {len(heads)} head/zone boxes, "
          f"{len(joints)} joint boxes verified")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print("VERIFY FAILED:", e); sys.exit(1)
