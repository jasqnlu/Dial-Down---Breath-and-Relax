import Testing
import Foundation
import SceneKit
@testable import BreathRelaxStretch

/// Coverage + consistency for the anatomy node map (anatomy_node_names.json) and
/// the OBJ parser behind the single-model Body Map. Every group/head/faceZone/
/// joint must be highlightable, and the parser must produce exactly the mapped nodes.
struct MuscleNodeNamesTests {
    private var muscleHeads: [String] { MuscleGroup.muscleHeads.filter { $0.value != "Head" }.map(\.key) }
    private var faceZones: [String] { MuscleGroup.muscleHeads.filter { $0.value == "Head" }.map(\.key) }

    @Test func everyMuscleGroupHasNodes() {
        for g in MuscleGroup.allCases {
            #expect(!(MuscleNodeNames.nodesByGroup[g.rawValue] ?? []).isEmpty, "\(g.rawValue) has no nodes")
        }
    }
    @Test func everyMuscleHeadHasNodes() {
        for h in muscleHeads { #expect(!(MuscleNodeNames.nodesByHead[h] ?? []).isEmpty, "\(h) has no nodes") }
    }
    @Test func everyFaceZoneHasNodes() {
        for z in faceZones { #expect(!(MuscleNodeNames.nodesByFaceZone[z] ?? []).isEmpty, "\(z) has no nodes") }
    }
    @Test func everyJointRegionHasNodes() {
        for j in JointRegion.allNames { #expect(!(MuscleNodeNames.nodesByJoint[j] ?? []).isEmpty, "\(j) has no nodes") }
    }
    @Test func nodeNamesResolvesAllRegionKinds() {
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Biceps").isEmpty)              // group
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Triceps Long Head").isEmpty)   // head
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Eye").isEmpty)                 // face zone (now real)
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Elbow").isEmpty)               // joint (now real)
        #expect(MuscleNodeNames.nodeNames(forRegion: "Nonsense Region").isEmpty)
    }
    @Test func parserBuildsExactlyTheMappedNodes() async {
        guard let parts = await BodyMeshLoader.shared.anatomyParts() else {
            Issue.record("BodyAnatomy.obj failed to parse"); return
        }
        #expect(Set(parts.map(\.name)) == Set(MuscleNodeNames.layerByNode.keys), "parsed nodes differ from map keys")
        for part in parts {
            #expect(part.layer == MuscleNodeNames.layerByNode[part.name])
            #expect(part.element.primitiveCount > 0, "\(part.name) has no triangles")
        }
    }
}
