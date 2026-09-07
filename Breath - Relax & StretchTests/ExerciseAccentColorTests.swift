import Testing
import SwiftUI
import UIKit
@testable import BreathRelaxStretch

struct ExerciseAccentColorTests {
    @Test func sameNameAlwaysProducesSameHue() {
        let first = Color.exerciseHue(for: "Standing Quad Stretch")
        let second = Color.exerciseHue(for: "Standing Quad Stretch")
        #expect(first == second)
    }

    @Test func differentNamesProduceDifferentHues() {
        let a = Color.exerciseHue(for: "Standing Quad Stretch")
        let b = Color.exerciseHue(for: "Seated Neck Rolls")
        let c = Color.exerciseHue(for: "Box Breathing")
        #expect(a != b)
        #expect(b != c)
        #expect(a != c)
    }

    @Test func hueStaysWithinUnitRange() {
        for name in ["Child's Pose", "Downward-Facing Dog", "", "Right Cossack Squat Stretch"] {
            let hue = Color.exerciseHue(for: name)
            #expect(hue >= 0 && hue < 1)
        }
    }

    @Test func perExerciseColorAvoidsWhiteBlackAndExtremes() {
        for name in ["Standing Quad Stretch", "Seated Neck Rolls", "Box Breathing"] {
            let uiColor = UIColor(Color.forExercise(named: name))
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            #expect(saturation > 0.3, "saturation \(saturation) too washed out for \(name)")
            #expect(brightness > 0.3 && brightness < 0.85, "brightness \(brightness) too dark/light for \(name)")
        }
    }
}
