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
    check(classify_joint("Articular capsule of elbow joint.l"), "Left Elbow", "elbow.l")
    check(classify_joint("Annular ligament of radius.r"), "Right Elbow", "annular.r")
    check(classify_joint("Articular capsule of radiocarpal joint.l"), "Left Wrist", "wrist.l")
    check(classify_joint("Articular capsule of hip joint.r"), "Right Hip", "hip.r")
    check(classify_joint("Anterior cruciate ligament.l"), "Left Knee", "acl.l")
    check(classify_joint("Medial meniscus.r"), "Right Knee", "meniscus.r")
    check(classify_joint("Anterior talofibular ligament.l"), "Left Ankle", "ankle.l")
    # Spine buckets by the FIRST vertebra letter of the disc level.
    check(classify_joint("Intervertebral disc C5-C6"), "Neck", "cervical disc")
    check(classify_joint("Nucleus pulposus C7-T1"), "Neck", "cervicothoracic -> neck")
    check(classify_joint("Intervertebral disc T4-T5"), "Upper Spine", "thoracic disc")
    check(classify_joint("Intervertebral disc T12-L1"), "Upper Spine", "T12-L1 -> upper")
    check(classify_joint("Intervertebral disc L4-L5"), "Lower Spine", "lumbar disc")
    check(classify_joint("Nucleus pulposus L5-S1"), "Lower Spine", "L5-S1 -> lower")
    # Non-kept joints and label anchors -> None.
    check(classify_joint("Articular capsules of metacarpophalangeal joints"), None, "finger joints")
    check(classify_joint("Hip joint.j"), None, "label anchor (no side)")
    check(classify_joint("Biceps brachii muscle.l"), None, "muscle, not joint")

if __name__ == "__main__":
    test_face_zones(); test_joints()
    print("OK: classification tests passed")
