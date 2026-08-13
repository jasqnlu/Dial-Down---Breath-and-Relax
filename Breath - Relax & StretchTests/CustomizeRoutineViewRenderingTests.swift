import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct CustomizeRoutineViewRenderingTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name, type: .stretch,
            targetBodyParts: ["Lower Back"], durationSeconds: duration,
            difficulty: 1, instructions: [], cueStyle: .hold
        )
    }

    @Test func rendersWithExercises() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180), makeExercise(name: "Cat-Cow Flow", duration: 90)]
        let view = CustomizeRoutineView(title: "Wake Up", exercises: exercises, isPinned: false, onAddExercisesRequested: {}, onDone: { _, _ in })
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithPinnedStateOn() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180)]
        let view = CustomizeRoutineView(title: "Wake Up", exercises: exercises, isPinned: true, onAddExercisesRequested: {}, onDone: { _, _ in })
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithNoExercises() {
        let view = CustomizeRoutineView(title: "Wake Up", exercises: [], isPinned: false, onAddExercisesRequested: {}, onDone: { _, _ in })
        let renderer = ImageRenderer(content: view.frame(width: 390, height: 700))
        #expect(renderer.cgImage != nil)
    }
}
