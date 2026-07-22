"""Pure-Python unit tests for the Z-Anatomy name classifiers.
Run: python3 Tools/blender/test_classification.py   (stdlib only, no Blender)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from muscle_classification import classify_face_zone, classify_joint

def check(actual, expected, label):
    assert actual == expected, f"{label}: got {actual!r}, expected {expected!r}"

def test_face_zones():
    check(classify_face_zone("Orbital part of orbicularis oculi.l"), "Left Eye", "eye.l")
    check(classify_face_zone("Palpebral part of orbicularis oculi.r"), "Right Eye", "eye.r")
    check(classify_face_zone("Temporalis muscle.l"), "Left Temple", "temple.l")
    check(classify_face_zone("Deep part of masseter.r"), "Right Jaw", "jaw.r")
    check(classify_face_zone("Frontalis muscle.l"), "Forehead", "forehead.l->midline")
    check(classify_face_zone("Frontalis muscle.r"), "Forehead", "forehead.r->midline")
    # Fascia / region skin patches are NOT facial muscles.
    check(classify_face_zone("Masseteric fascia.l"), None, "masseteric fascia")
    check(classify_face_zone("Parotideomasseteric region.l"), None, "masseter region")
    # Insertion markers (.o2l etc.) have no trustworthy side -> skipped.
    check(classify_face_zone("Temporalis muscle.o2l"), None, "temporalis insertion")
    check(classify_face_zone("Biceps brachii muscle.l"), None, "non-face muscle")

def test_joints():
    check(classify_joint("Articular capsule of glenohumeral joint.l"), "Left Shoulder Joint", "gh.l")
    check(classify_joint("Articular capsule of acromioclavicular joint.r"), "Right Shoulder Joint", "ac.r")
    check(classify_joint("Articular capsule of hip joint.r"), "Right Hip", "hip.r")
    check(classify_joint("Articular capsule of hip joint.l"), "Left Hip", "hip.l")
    # Spine buckets by the FIRST vertebra letter of the disc level.
    check(classify_joint("Intervertebral disc C5-C6"), "Neck", "cervical disc")
    check(classify_joint("Nucleus pulposus C7-T1"), "Neck", "cervicothoracic -> neck")
    check(classify_joint("Intervertebral disc L4-L5"), "Lower Spine", "lumbar disc")
    check(classify_joint("Nucleus pulposus L5-S1"), "Lower Spine", "L5-S1 -> lower")
    # Non-kept joints (removed: elbow, wrist, knee, ankle) now return None.
    check(classify_joint("Articular capsule of elbow joint.l"), None, "elbow.l")
    check(classify_joint("Articular capsule of radiocarpal joint.l"), None, "wrist.l")
    check(classify_joint("Anterior cruciate ligament.l"), None, "acl.l")
    check(classify_joint("Anterior talofibular ligament.l"), None, "ankle.l")
    # Thoracic discs also return None now.
    check(classify_joint("Intervertebral disc T4-T5"), None, "thoracic disc")
    # Non-kept joints and label anchors -> None.
    check(classify_joint("Articular capsules of metacarpophalangeal joints"), None, "finger joints")
    check(classify_joint("Hip joint.j"), None, "label anchor (no side)")
    check(classify_joint("Biceps brachii muscle.l"), None, "muscle, not joint")

def test_joint_bucketing():
    from classify_joint_hitboxes import bucket_joint_boxes
    fixture = {
        # two objects of the same hip joint on the left -> unioned into one box
        "Articular capsule of hip joint.l": {"min": [0.10, 0.20, -0.02], "max": [0.20, 0.30, 0.02]},
        "Iliofemoral ligament.l":           {"min": [0.15, 0.18, -0.03], "max": [0.22, 0.24, 0.01]},
        # right hip -> separate bucket
        "Articular capsule of hip joint.r": {"min": [-0.20, 0.20, -0.02], "max": [-0.10, 0.30, 0.02]},
        # cervical disc -> Neck
        "Intervertebral disc C5-C6":        {"min": [-0.03, 0.55, -0.05], "max": [0.03, 0.60, 0.02]},
        # non-kept -> dropped
        "Articular capsules of metacarpophalangeal joints": {"min": [0, 0, 0], "max": [0.01, 0.01, 0.01]},
    }
    out = bucket_joint_boxes(fixture)
    check(set(out.keys()), {"Left Hip", "Right Hip", "Neck"}, "joint buckets")
    # Left Hip unions both left objects.
    check(out["Left Hip"]["min"], [0.10, 0.18, -0.03], "left hip min union")
    check(out["Left Hip"]["max"], [0.22, 0.30, 0.02], "left hip max union")

if __name__ == "__main__":
    test_face_zones(); test_joints(); test_joint_bucketing()
    print("OK: classification tests passed")
