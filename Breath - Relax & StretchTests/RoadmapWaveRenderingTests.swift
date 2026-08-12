import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct RoadmapWaveRenderingTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name,
            type: .stretch,
            targetBodyParts: ["Lower Back"],
            durationSeconds: duration,
            difficulty: 1,
            instructions: [],
            cueStyle: .hold
        )
    }

    @Test func rendersWithMultipleExercises() {
        let exercises = [
            makeExercise(name: "Box Breathing", duration: 180),
            makeExercise(name: "Cat-Cow Flow", duration: 90),
            makeExercise(name: "Shoulder Roll", duration: 30),
        ]
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersNumberedVariant() {
        let exercises = [makeExercise(name: "Box Breathing", duration: 180), makeExercise(name: "Cat-Cow Flow", duration: 90)]
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises, numbered: true).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithASingleExercise() {
        let renderer = ImageRenderer(content: RoadmapWave(exercises: [makeExercise(name: "Box Breathing", duration: 180)]).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithNoExercisesWithoutCrashing() {
        let renderer = ImageRenderer(content: RoadmapWave(exercises: []).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }
}
