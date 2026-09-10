import Testing
@testable import BreathRelaxStretch

// Bundled seed exercises need a UUID that means the same thing across
// installs and devices — Session/Routine exerciseIDs and Supabase's
// RemoteExercise.id all compare it directly, since Exercise.init's default
// uuid parameter would otherwise generate a fresh random one each time.
//
// seedIfNeeded() (Breath__Relax___StretchApp.swift) now parses SeedData.json's
// own permanent "id" field as that uuid — independent of `name`, so renaming
// an exercise in the catalog doesn't change the uuid a fresh install gets for
// it. Exercise.stableSeedUUID(forName:) only remains as a fallback for a seed
// entry with a missing/malformed id.
struct ExerciseTests {

    @Test func stableSeedUUIDIsDeterministicForSameName() {
        let a = Exercise.stableSeedUUID(forName: "Neck Rolls")
        let b = Exercise.stableSeedUUID(forName: "Neck Rolls")
        #expect(a == b)
    }

    @Test func stableSeedUUIDDiffersForDifferentNames() {
        let a = Exercise.stableSeedUUID(forName: "Neck Rolls")
        let b = Exercise.stableSeedUUID(forName: "Shoulder Shrugs")
        #expect(a != b)
    }
}
