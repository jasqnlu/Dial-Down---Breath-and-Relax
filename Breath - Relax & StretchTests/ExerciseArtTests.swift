import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct ExerciseArtTests {
    private func makeExercise(name: String = "Test", animationName: String? = nil) -> Exercise {
        let exercise = Exercise(
            name: name,
            type: .stretch,
            targetBodyParts: ["Lower Back"],
            durationSeconds: 45,
            difficulty: 1,
            instructions: [],
            cueStyle: .hold
        )
        exercise.animationName = animationName
        return exercise
    }

    @Test func thresholdIsFiftyTwoPoints() {
        #expect(ExerciseArt.animationThreshold == 52)
    }

    @Test func rendersAtGlyphSizeWithoutAnimation() {
        let exercise = makeExercise()
        let renderer = ImageRenderer(content: ExerciseArt(exercise: exercise, category: .back, size: 30))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersAtTileSizeWithoutAnimation() {
        // No demoVideoURL resolves -> falls back to PoseGlyphIcon even
        // though the size is above the animation threshold.
        let exercise = makeExercise()
        let renderer = ImageRenderer(content: ExerciseArt(exercise: exercise, category: .back, size: 112))
        #expect(renderer.cgImage != nil)
    }
}
