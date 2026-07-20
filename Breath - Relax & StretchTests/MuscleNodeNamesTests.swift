import Testing
import Foundation
import SceneKit
@testable import BreathRelaxStretch

/// Coverage + consistency for the muscle-mesh node map (musclegroup_node_names.json)
/// and the OBJ parser that backs the Body Map's muscle-layer reveal. Guards the
/// contract the highlight + hit-test rely on: every group/head is highlightable,
/// and the parser produces exactly the nodes the map names.
struct MuscleNodeNamesTests {
    /// Face zones (Eye/Temple/Jaw/Forehead) live on the skin with no muscle
    /// geometry — they parent to the coarse "Head" group. The mesh covers only
    /// the sub-heads that parent to a Left/Right muscle group.
    private var muscleHeads: [String] {
        MuscleGroup.muscleHeads.filter { $0.value != "Head" }.map(\.key)
    }

    @Test func everyMuscleGroupHasAtLeastOneNode() {
        for group in MuscleGroup.allCases {
            let nodes = MuscleNodeNames.nodesByGroup[group.rawValue] ?? []
            #expect(!nodes.isEmpty, "\(group.rawValue) has no muscle nodes")
        }
    }

    @Test func everyMuscleHeadHasAtLeastOneNode() {
        for head in muscleHeads {
            let nodes = MuscleNodeNames.nodesByHead[head] ?? []
            #expect(!nodes.isEmpty, "\(head) has no muscle nodes")
        }
    }

    @Test func everyNodeMapsToARealMuscleGroup() {
        let valid = Set(MuscleGroup.allCases.map(\.rawValue))
        for (node, group) in MuscleNodeNames.groupByNode {
            #expect(valid.contains(group), "\(node) → unknown group \(group)")
        }
    }

    /// A headed node must belong to the same group its head parents to —
    /// otherwise a head highlight and its group highlight would light different
    /// pieces. (Verified against the shipped data: 0 violations.)
    @Test func headNodesShareTheirHeadsParentGroup() {
        for (node, head) in MuscleNodeNames.headByNode {
            let parent = MuscleGroup.parentOfHead(head)
            #expect(MuscleNodeNames.groupByNode[node] == parent,
                    "\(node): head \(head) parents to \(parent ?? "nil") but group is \(MuscleNodeNames.groupByNode[node] ?? "nil")")
        }
    }

    @Test func nodeNamesForRegionResolvesGroupsAndHeads() {
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Biceps").isEmpty)
        #expect(!MuscleNodeNames.nodeNames(forRegion: "Left Triceps Long Head").isEmpty)
        // No muscle geometry for face zones, joints, or unknown regions.
        #expect(MuscleNodeNames.nodeNames(forRegion: "Left Eye").isEmpty)
        #expect(MuscleNodeNames.nodeNames(forRegion: "Left Elbow").isEmpty)
        #expect(MuscleNodeNames.nodeNames(forRegion: "Nonsense Region").isEmpty)
    }

    /// The hit-test resolves a tapped node to the finest CURRENT candidate: the
    /// head when both the head and its parent group are on offer, else the group.
    @Test func matchingCandidatePrefersHeadOverGroup() throws {
        let headNode = try #require(MuscleNodeNames.nodesByHead["Left Triceps Long Head"]?.first)
        let both: Set<String> = ["Left Triceps", "Left Triceps Long Head"]
        #expect(MuscleNodeNames.matchingCandidate(forNode: headNode, among: both) == "Left Triceps Long Head")
        let groupOnly: Set<String> = ["Left Triceps"]
        #expect(MuscleNodeNames.matchingCandidate(forNode: headNode, among: groupOnly) == "Left Triceps")
        #expect(MuscleNodeNames.matchingCandidate(forNode: headNode, among: ["Right Biceps"]) == nil)
    }

    /// End-to-end: the OBJ parser BodySceneView uses builds exactly the node set
    /// the map describes, each tagged with the map's group. This is what makes
    /// SceneKit's OBJ-merging irrelevant — the app never relies on SceneKit names.
    @Test func parserBuildsExactlyTheMappedNodes() async {
        guard let parts = await BodyMeshLoader.shared.muscleParts() else {
            Issue.record("BodyMuscle.obj failed to parse")
            return
        }
        let parsed = Set(parts.map(\.name))
        let mapped = Set(MuscleNodeNames.groupByNode.keys)
        #expect(parsed == mapped, "parsed nodes differ from map keys")
        for part in parts {
            #expect(part.group == MuscleNodeNames.groupByNode[part.name],
                    "\(part.name) parsed group \(part.group) != map group")
            // Every piece has real triangle geometry.
            #expect(part.element.primitiveCount > 0, "\(part.name) has no triangles")
        }
    }
}
