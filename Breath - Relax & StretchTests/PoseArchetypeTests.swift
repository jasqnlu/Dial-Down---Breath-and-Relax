import Testing
import CoreGraphics
@testable import BreathRelaxStretch

struct PoseArchetypeTests {
    @Test func everyArchetypeIDHasALibraryEntry() {
        for id in PoseArchetypeID.allCases {
            #expect(PoseArchetypeLibrary.all[id] != nil, "\(id) is missing from PoseArchetypeLibrary.all")
        }
    }

    @Test func everyArchetypeHasBothArmsAndBothLegsWhereApplicable() {
        // Every archetype except headMicro-style ones has 4 limb chains
        // (left arm, right arm, left leg, right leg) plus the spine —
        // 5 chains total. None of our 16 initial archetypes are head-only.
        for (id, archetype) in PoseArchetypeLibrary.all {
            #expect(archetype.limbs.count == 5, "\(id) should have 5 path chains (spine + 2 arms + 2 legs), has \(archetype.limbs.count)")
            for limb in archetype.limbs {
                #expect(limb.count >= 2, "\(id) has a limb chain with fewer than 2 points")
            }
        }
    }

    @Test func everyCoordinateIsWithinNormalizedBounds() {
        for (id, archetype) in PoseArchetypeLibrary.all {
            let allPoints = archetype.limbs.flatMap { $0 } + archetype.jointDots + [archetype.headCenter]
            for point in allPoints {
                #expect((0.0...1.0).contains(point.x), "\(id) has an out-of-bounds x: \(point.x)")
                #expect((0.0...1.0).contains(point.y), "\(id) has an out-of-bounds y: \(point.y)")
            }
            #expect(archetype.headRadius > 0, "\(id) has a non-positive headRadius")
        }
    }
}
