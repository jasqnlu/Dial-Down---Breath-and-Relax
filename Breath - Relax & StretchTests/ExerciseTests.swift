import Testing
@testable import BreathRelaxStretch

// Exercise.stableSeedUUID(forName:) is what keeps bundled seed exercises'
// UUIDs stable across installs — without it Session/Routine exerciseIDs and
// Supabase's RemoteExercise.id would compare UUIDs that mean nothing between
// two devices, since Exercise.init's default uuid parameter generates a fresh
// random one each time.
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
