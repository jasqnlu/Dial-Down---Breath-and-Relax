import Testing
import Foundation
import SceneKit
@testable import BreathRelaxStretch

/// Coverage + consistency for the skin+muscle node map (skinmuscle_node_names.json)
/// and the OBJ parser behind the skin-covered Body Map. Every group/head/faceZone
/// must be highlightable; joints are hitbox-only (no mesh nodes); the parser must
/// produce exactly the mapped nodes.
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
    /// Joints are hitbox-only now (Task 4/5 pivot) — no mesh node maps to a joint;
    /// they resolve to their crossing muscles' exercises via `MuscleGroup.oldRegionMap`
    /// instead of a highlightable node set.
    @Test func jointsHaveNoMuscleNodes() {
        #expect(MuscleNodeNames.nodesByJoint.isEmpty)
        for j in JointRegion.allNames {
            #expect(MuscleNodeNames.nodeNames(forRegion: j).isEmpty, "\(j) should have no nodes (hitbox-only)")
        }
    }
    @Test func exactlyOneSkinNode() {
        let skinNodes = MuscleNodeNames.layerByNode.filter { $0.value == "skin" }
        #expect(skinNodes.count == 1, "expected exactly one skin node, found \(skinNodes.count)")
    }
    @Test func nodeNamesResolvesAllRegionKinds() {
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Biceps").isEmpty)              // group
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Triceps Long Head").isEmpty)   // head
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Eye").isEmpty)                 // face zone
        #expect(MuscleNodeNames.nodeNames(forRegion: "Nonsense Region").isEmpty)
    }
    @Test func parserBuildsExactlyTheMappedNodes() async {
        guard let parts = await BodyMeshLoader.shared.anatomyParts() else {
            Issue.record("BodySkinMuscle.obj failed to parse"); return
        }
        #expect(Set(parts.map(\.name)) == Set(MuscleNodeNames.layerByNode.keys), "parsed nodes differ from map keys")
        for part in parts {
            #expect(part.layer == MuscleNodeNames.layerByNode[part.name])
            #expect(part.element.primitiveCount > 0, "\(part.name) has no triangles")
        }
    }
}
