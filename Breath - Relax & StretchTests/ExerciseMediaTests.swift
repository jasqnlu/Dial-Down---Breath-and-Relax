import Testing
@testable import BreathRelaxStretch

struct ExerciseMediaTests {
    @Test func localVideoURLNilWhenUnset() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.localVideoURL == nil)
    }

    @Test func localVideoURLNilWhenFileMissing() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.localVideoName = "definitely_not_bundled.mp4"
        #expect(e.localVideoURL == nil)   // missing file → placeholder, never broken player
    }
}
