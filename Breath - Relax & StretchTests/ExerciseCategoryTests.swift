import Testing
import SwiftUI
import UIKit
@testable import BreathRelaxStretch

struct ExerciseCategoryTests {
    @Test func everyMuscleGroupMapsToExactlyOneCategory() {
        for group in MuscleGroup.allCases {
            let categories = ExerciseCategory.categories(for: [group.rawValue])
            #expect(categories.count == 1, "MuscleGroup \(group.rawValue) should map to exactly one category")
        }
    }

    @Test func singlePartMapsToExpectedCategory() {
        #expect(ExerciseCategory.categories(for: ["Left Quadriceps"]) == [.legs])
        #expect(ExerciseCategory.categories(for: ["Left Abs"]) == [.core])
        #expect(ExerciseCategory.categories(for: ["Head"]) == [.neck])
    }

    @Test func exerciseSpanningCategoriesMapsToBoth() {
        let categories = ExerciseCategory.categories(for: ["Left Chest", "Left Shoulder"])
        #expect(categories == [.chest, .shoulders])
    }

    @Test func unknownPartNameIsIgnored() {
        #expect(ExerciseCategory.categories(for: ["Not A Real Part"]).isEmpty)
    }

    @Test func allCategoriesHaveEightCases() {
        #expect(ExerciseCategory.allCases.count == 8)
    }

    @Test func primaryPicksFirstCategoryInDeclarationOrder() {
        // categories(for:) returns {.chest, .shoulders}; shoulders is declared
        // before chest in ExerciseCategory, so it wins deterministically.
        #expect(ExerciseCategory.primary(for: ["Left Chest", "Left Shoulder"]) == .shoulders)
    }

    @Test func primaryFallsBackToCoreWhenNoPartsMatch() {
        #expect(ExerciseCategory.primary(for: ["Not A Real Part"]) == .core)
    }

    @Test func neckAccentColorIsNotCyanAdjacent() {
        #expect(ExerciseCategory.neck.accentColor != Color.teal)
        #expect(ExerciseCategory.neck.accentColor == Color.brown)
    }

    /// Regression guard for the .neck/.chest collision (`.red` vs `.pink`,
    /// ~14deg apart in hue, near-identical at the small sizes accent colors
    /// are used at). Walks every unordered pair of the 8 category colors as
    /// resolved in dark mode and asserts they're separated by at least
    /// `minDistance` in RGB space.
    ///
    /// Threshold reasoning: measured pairwise Euclidean RGB distances (each
    /// channel 0...1) across the current 8 dark-mode colors
    /// (.brown neck, .orange shoulders, .pink chest, .indigo back,
    /// .yellow core, .blue arms, .purple hipsGlutes, .green legs) and the
    /// real minimum came out well above 0.3. The old .red/.pink pair
    /// (system red ~#FF453A vs system pink ~#FF375F in dark mode) measures a
    /// distance of roughly 0.09 - clearly under 0.3. Choosing 0.25 sits
    /// comfortably below the current real minimum while staying well above
    /// what the old colliding pair would have measured, so this test would
    /// have caught the original collision.
    @Test func allCategoryAccentColorsAreDistinctInDarkMode() {
        let minDistance: CGFloat = 0.25

        func rgb(_ color: Color) -> (CGFloat, CGFloat, CGFloat) {
            let resolved = UIColor(color)
                .resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
            return (r, g, b)
        }

        let categories = ExerciseCategory.allCases
        for i in 0..<categories.count {
            for j in (i + 1)..<categories.count {
                let (r1, g1, b1) = rgb(categories[i].accentColor)
                let (r2, g2, b2) = rgb(categories[j].accentColor)
                let distance = ((r1 - r2) * (r1 - r2)
                    + (g1 - g2) * (g1 - g2)
                    + (b1 - b2) * (b1 - b2)).squareRoot()
                #expect(distance > minDistance,
                        "\(categories[i]) and \(categories[j]) are too close: distance \(distance)")
            }
        }
    }
}
