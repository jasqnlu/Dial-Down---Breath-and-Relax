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

    @Test func curveRendersAtAnOffCenterFocusWithoutCrashing() {
        let renderer = ImageRenderer(content:
            RoadmapWaveCurve(count: 5, midY: 100, focusCenterX: 340, padding: 300)
                .frame(width: 600, height: 200)
        )
        #expect(renderer.cgImage != nil)
    }

    @Test func curveRendersWithASingleNodeWithoutCrashing() {
        let renderer = ImageRenderer(content:
            RoadmapWaveCurve(count: 1, midY: 100, focusCenterX: 24, padding: 100)
                .frame(width: 200, height: 200)
        )
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithManyExercisesAtCarouselWidthWithoutCrashing() {
        // A width narrower than the full content forces the carousel's
        // scroll/snap/focus machinery to actually engage, unlike the
        // existing 360pt-wide tests which happen to fit everything.
        let exercises = (0..<8).map { makeExercise(name: "Exercise \($0)", duration: 30 + $0 * 15) }
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises, numbered: true).frame(width: 320, height: 260))
        #expect(renderer.cgImage != nil)
    }

    @Test func rendersWithMixedCategoryExercisesWithoutCrashing() {
        let exercises = [
            Exercise(name: "Seated Neck Rolls", type: .stretch, targetBodyParts: ["Head"],
                     durationSeconds: 35, difficulty: 1, instructions: [], cueStyle: .hold),
            Exercise(name: "Shoulder Roll", type: .stretch, targetBodyParts: ["Left Shoulder"],
                     durationSeconds: 60, difficulty: 1, instructions: [], cueStyle: .hold),
            Exercise(name: "Cobra Stretch", type: .stretch, targetBodyParts: ["Left Chest"],
                     durationSeconds: 45, difficulty: 1, instructions: [], cueStyle: .hold),
        ]
        let renderer = ImageRenderer(content: RoadmapWave(exercises: exercises, numbered: true).frame(width: 360, height: 140))
        #expect(renderer.cgImage != nil)
    }
}
