import Testing
@testable import BreathRelaxStretch

struct BodyMapLaunchStateTests {
    @Test func initialMarkedRegionsAreEmptyEvenWhenSavedRegionsExist() {
        let initial = BodyMapLaunchState.initialMarkedRegions(savedRegions: ["Left Chest", "Right Shoulder"])

        #expect(initial.isEmpty)
    }
}
