import CoreGraphics
import Testing
@testable import BreathRelaxStretch

struct TouchGlyphLibraryTests {
    @Test func everyExerciseCategoryHasATouchGlyph() {
        for category in ExerciseCategory.allCases {
            #expect(TouchGlyphLibrary.all[category] != nil, "\(category) is missing a TouchGlyphArchetype")
        }
    }

    @Test func everyCoordinateIsWithinNormalizedBounds() {
        for (category, archetype) in TouchGlyphLibrary.all {
            let points = archetype.spine + archetype.legLeft + archetype.legRight
                + archetype.restingArm + archetype.pointingArm
                + [archetype.headCenter, archetype.contactPoint]
            for point in points {
                #expect((0.0...1.0).contains(point.x), "\(category) has an out-of-bounds x: \(point.x)")
                #expect((0.0...1.0).contains(point.y), "\(category) has an out-of-bounds y: \(point.y)")
            }
            #expect(archetype.headRadius > 0, "\(category) has a non-positive headRadius")
        }
    }

    @Test func everyLimbChainHasAtLeastTwoPoints() {
        for (category, archetype) in TouchGlyphLibrary.all {
            for chain in [archetype.spine, archetype.legLeft, archetype.legRight, archetype.restingArm, archetype.pointingArm] {
                #expect(chain.count >= 2, "\(category) has a limb chain with fewer than 2 points")
            }
        }
    }
}
