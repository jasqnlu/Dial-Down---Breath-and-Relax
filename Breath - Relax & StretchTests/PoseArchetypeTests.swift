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

    @Test func everyArchetypeFitsInsideTheCircularBadge() {
        // PoseGlyphIcon renders into a circle of radius 0.5 (normalized figure
        // space), un-clipped. Every stroked point needs headroom for the
        // stroke's own half-width; the head circle needs headroom for its
        // own radius. This catches geometry that would render as a stray
        // disc or clipped limb outside the badge, which no other test can see.
        let strokeHalfWidth = 0.073 / 2  // matches PoseGlyphIcon's StrokeStyle lineWidth ratio
        let center = CGPoint(x: 0.5, y: 0.5)
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (pow(a.x - b.x, 2) + pow(a.y - b.y, 2)).squareRoot()
        }
        for (id, archetype) in PoseArchetypeLibrary.all {
            let headBudget = 0.5 - archetype.headRadius
            #expect(distance(archetype.headCenter, center) <= headBudget,
                     "\(id) head circle extends outside the badge")
            let allStrokedPoints = archetype.limbs.flatMap { $0 } + archetype.jointDots
            for point in allStrokedPoints {
                #expect(distance(point, center) <= 0.5 - strokeHalfWidth,
                         "\(id) has a point at \(point) outside the badge")
            }
        }
    }
}
