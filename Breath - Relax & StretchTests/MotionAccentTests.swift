import Testing
@testable import BreathRelaxStretch

struct MotionAccentTests {
    @Test func exactCircularExercisesResolveToCircularAccent() {
        for name in ["Shoulder Roll", "Seated Neck Rolls", "Wrist Circles",
                     "Standing Hip Circles", "Ankle Alphabet"] {
            let exercise = Exercise(name: name, type: .stretch,
                                    targetBodyParts: [], durationSeconds: 30,
                                    difficulty: 1, instructions: [])
            #expect(MotionAccent.resolve(for: exercise) == .circular)
        }
    }

    @Test func repeatedButNonCircularExercisesRemainUnaccented() {
        for name in ["Cat-Cow Flow", "Dynamic Standing Leg Swings", "Left Wrist Flexor Stretch"] {
            let exercise = Exercise(name: name, type: .stretch,
                                    targetBodyParts: [], durationSeconds: 30,
                                    difficulty: 1, instructions: [], cueStyle: .repeatMotion)
            #expect(MotionAccent.resolve(for: exercise) == .none)
        }
    }

    @Test func stableSeedIDResolvesEvenWhenNameChanges() {
        let exercise = Exercise(name: "Renamed Shoulder Exercise", type: .stretch,
                                targetBodyParts: [], durationSeconds: 30,
                                difficulty: 1, instructions: [])
        exercise.seedID = "0510c366-18e8-4ff1-a341-6a19976e50a4"
        #expect(MotionAccent.resolve(for: exercise) == .circular)
    }
}
