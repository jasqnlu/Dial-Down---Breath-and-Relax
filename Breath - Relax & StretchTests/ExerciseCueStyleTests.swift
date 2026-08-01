import Testing
@testable import BreathRelaxStretch

struct ExerciseCueStyleTests {
    @Test func defaultsToHold() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.cueStyle == .hold)
    }

    @Test func initAcceptsExplicitCueStyle() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [],
                         cueStyle: .repeatMotion)
        #expect(e.cueStyle == .repeatMotion)
    }

    @Test func rawValuesMatchCapitalizedSeedStrings() {
        // Breath__Relax___StretchApp.swift parses seed JSON via
        // `ExerciseCueStyle(rawValue: rawStr.capitalized)` against lowercase
        // "hold"/"repeat" bundle strings — verify that lookup actually works.
        #expect(ExerciseCueStyle(rawValue: "hold".capitalized) == .hold)
        #expect(ExerciseCueStyle(rawValue: "repeat".capitalized) == .repeatMotion)
    }
}
