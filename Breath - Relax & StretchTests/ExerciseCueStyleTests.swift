import Testing
import Foundation
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

    /// Regression test for a real crash: `cueStyle` was originally a
    /// directly-persisted `ExerciseCueStyle` enum property. SwiftData's
    /// lightweight migration cannot safely decode a custom enum-typed
    /// property added after real data already exists — reading `.cueStyle`
    /// on a pre-existing on-disk row threw a forced-cast failure
    /// (`swift_dynamicCastFailure`) inside the SwiftData-generated getter,
    /// crashing the app on launch inside `SeedMigrator.migrateV8` (which
    /// itself has to read `.cueStyle` before it can decide whether to
    /// backfill it). The fix stores a plain `cueStyleRaw: String` instead
    /// (mirroring the `posesData`/`poses` pattern already used for
    /// `ExercisePose`), with `cueStyle` as a computed property that falls
    /// back to `.hold` for any unparseable/unexpected raw value — exactly
    /// the state a pre-migration on-disk row's raw storage could be in.
    @Test func cueStyleFallsBackToHoldForUnparseableRawStorage() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.cueStyleRaw = "garbage-value-that-matches-no-case"
        #expect(e.cueStyle == .hold)
    }
}
