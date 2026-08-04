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

    // MARK: - Demo clip source (filmed video vs. generated animation)

    @Test func demoVideoNameNilWhenNoClips() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.demoVideoName == nil)
    }

    @Test func demoVideoNameUsesAnimationWhenOnlyAnimationSet() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationName = "clasped_hands.mp4"
        #expect(e.demoVideoName == "clasped_hands.mp4")
    }

    @Test func demoVideoNamePrefersFilmedVideoOverAnimation() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationName = "clasped_hands.mp4"
        e.localVideoName = "jason_clasped.mp4"
        #expect(e.demoVideoName == "jason_clasped.mp4")   // hero footage wins
    }

    @Test func demoVideoNameSkipsEmptyFilmedName() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationName = "clasped_hands.mp4"
        e.localVideoName = ""
        #expect(e.demoVideoName == "clasped_hands.mp4")   // empty name is not a clip
    }

    @Test func animationVideoURLNilWhenFileMissing() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationName = "definitely_not_bundled.mp4"
        #expect(e.animationVideoURL == nil)   // missing file → placeholder, never broken player
    }

    @Test func demoVideoURLNilWhenNoClips() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.demoVideoURL == nil)
    }

    // MARK: - Demo orientation (drives the card's aspect ratio)

    @Test func demoIsAnimationWhenOnlyAnimationSet() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationName = "clasped_hands.mp4"
        #expect(e.demoIsAnimation)   // portrait figure
    }

    @Test func demoIsNotAnimationWhenFilmedPresent() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationName = "clasped_hands.mp4"
        e.localVideoName = "jason_clasped.mp4"
        #expect(!e.demoIsAnimation)  // filmed clip → landscape
    }

    @Test func demoIsNotAnimationWhenNoClips() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(!e.demoIsAnimation)
    }
}
