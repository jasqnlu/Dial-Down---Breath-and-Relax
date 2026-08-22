import Testing
@testable import BreathRelaxStretch

struct TourCoordinatorTests {
    @Test func catalogHasNineteenStepsWithUniqueIDs() {
        let steps = TourStep.allSteps
        #expect(steps.count == 19)
        #expect(Set(steps.map(\.id)).count == 19)
    }

    @Test func catalogHasSixSections() {
        let sectionStarts = TourStep.allSteps.filter { $0.tabIndex != nil }
        #expect(sectionStarts.count == 6)
        #expect(sectionStarts.map(\.tabIndex) == [0, 1, 2, 3, 4, 5])
    }
}
