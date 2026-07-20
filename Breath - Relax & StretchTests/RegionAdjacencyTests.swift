import Testing
@testable import BreathRelaxStretch

struct RegionAdjacencyTests {
    @Test func adjacencyIsSymmetric() {
        for (region, neighbors) in RegionAdjacency.neighbors {
            for n in neighbors {
                #expect(RegionAdjacency.adjacent(to: n).contains(region),
                        "\(region)→\(n) not mirrored by \(n)→\(region)")
            }
        }
    }

    @Test func everyMuscleGroupAndJointHasNeighbors() {
        // Head is handled by HeadZones, not adjacency — exclude it.
        for g in MuscleGroup.allCases where g != .head {
            #expect(!RegionAdjacency.adjacent(to: g.rawValue).isEmpty, "\(g.rawValue) has no neighbors")
        }
        for name in JointRegion.allNames {
            #expect(!RegionAdjacency.adjacent(to: name).isEmpty, "\(name) has no neighbors")
        }
    }

    @Test func everyNeighborNameIsARealRegion() {
        let valid = Set(MuscleGroup.allCases.map(\.rawValue)).union(JointRegion.allNames)
        for (region, neighbors) in RegionAdjacency.neighbors {
            #expect(valid.contains(region), "unknown key \(region)")
            for n in neighbors { #expect(valid.contains(n), "\(region)→ unknown \(n)") }
        }
    }

    @Test func chestIsNotAdjacentToForearmOrHand() {
        let chest = RegionAdjacency.adjacent(to: "Left Chest")
        #expect(!chest.contains("Left Forearm"))
        #expect(!chest.contains("Left Hand"))
    }

    @Test func elbowCrossesBicepsTricepsForearm() {
        let elbow = RegionAdjacency.adjacent(to: "Left Elbow")
        #expect(elbow.isSuperset(of: ["Left Biceps", "Left Triceps", "Left Forearm"]))
    }

    @Test func adjacencyStaysOnOneSide() {
        // A left-arm region should not list a right-arm region.
        #expect(!RegionAdjacency.adjacent(to: "Left Biceps").contains { $0.hasPrefix("Right ") && $0.contains("Biceps") })
    }
}
