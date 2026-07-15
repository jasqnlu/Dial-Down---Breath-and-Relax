import Testing
import Foundation
@testable import BreathRelaxStretch

struct HitboxDataTests {
    private struct Box: Decodable { let min: [Double]; let max: [Double] }

    private func loadBoxes(_ resource: String) throws -> [String: Box] {
        let url = try #require(Bundle.main.url(forResource: resource, withExtension: "json"))
        return try JSONDecoder().decode([String: Box].self, from: Data(contentsOf: url))
    }

    @Test func muscleBoxCountMatchesMuscleGroupCases() throws {
        let boxes = try loadBoxes("musclegroup_hitboxes")
        #expect(Set(boxes.keys) == Set(MuscleGroup.allCases.map(\.rawValue)))
    }

    /// Anatomical convention: the figure faces +Z, so its anatomical LEFT is
    /// world +x. This shipped inverted once (mirror convention) — pin it.
    @Test func leftBoxesArePositiveX_rightBoxesNegativeX() throws {
        let boxes = try loadBoxes("musclegroup_hitboxes")
        for (name, box) in boxes {
            let centerX = (box.min[0] + box.max[0]) / 2
            if name.hasPrefix("Left ")  { #expect(centerX > 0, "\(name) center x=\(centerX)") }
            if name.hasPrefix("Right ") { #expect(centerX < 0, "\(name) center x=\(centerX)") }
        }
    }

    @Test func jointBoxesExistWithAnatomicalSides() throws {
        let joints = try loadBoxes("joint_hitboxes")
        let expected = ["Elbow", "Wrist", "Knee", "Ankle"].flatMap { ["Left \($0)", "Right \($0)"] }
        #expect(Set(joints.keys) == Set(expected))
        for (name, box) in joints {
            let centerX = (box.min[0] + box.max[0]) / 2
            if name.hasPrefix("Left ")  { #expect(centerX > 0, "\(name)") }
            if name.hasPrefix("Right ") { #expect(centerX < 0, "\(name)") }
        }
    }

    /// A point at a joint-box center must resolve to the joint, not the
    /// bigger overlapping muscle boxes (smallest-volume tiebreak, real data).
    @Test func jointCentersResolveToJoints() {
        let volumes = BodyHitVolumes.all
        for joint in BodyHitVolumes.load(resource: "joint_hitboxes") {
            #expect(MuscleHitResolver.regionName(at: joint.center, in: volumes) == joint.name)
        }
    }

    /// Guards against the whole-body-vs-skin bbox normalization mismatch:
    /// every box must live inside the normalized body envelope.
    @Test func boxUnionFitsNormalizedBody() throws {
        let boxes = try loadBoxes("musclegroup_hitboxes")
        for (name, box) in boxes {
            #expect(box.min[1] >= -1.05 && box.max[1] <= 1.05, "\(name) y out of range")
            #expect(box.min[0] >= -0.9 && box.max[0] <= 0.9, "\(name) x out of range")
            for i in 0..<3 { #expect(box.min[i] < box.max[i], "\(name) degenerate axis \(i)") }
        }
    }
}
