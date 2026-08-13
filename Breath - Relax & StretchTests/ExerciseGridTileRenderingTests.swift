import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct ExerciseGridTileRenderingTests {
    private func makeExercise() -> Exercise {
        Exercise(
            name: "Cat-Cow Flow", type: .stretch,
            targetBodyParts: ["Lower Back"], durationSeconds: 90,
            difficulty: 1, instructions: [],
            cueStyle: .hold
        )
    }

    @Test func rendersWithNoBadge() {
        let renderer = ImageRenderer(content: ExerciseGridTile(exercise: makeExercise(), onTap: {}).frame(width: 160, height: 200))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithUnselectedAddBadge() {
        let tile = ExerciseGridTile(exercise: makeExercise(), badge: .add(isSelected: false), onTap: {}, onBadgeTap: {})
        let renderer = ImageRenderer(content: tile.frame(width: 160, height: 200))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithSelectedAddBadge() {
        let tile = ExerciseGridTile(exercise: makeExercise(), badge: .add(isSelected: true), onTap: {}, onBadgeTap: {})
        let renderer = ImageRenderer(content: tile.frame(width: 160, height: 200))
        #expect(renderer.cgImage != nil)
    }
}
