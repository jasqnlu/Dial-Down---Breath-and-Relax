import Testing
@testable import BreathRelaxStretch

struct TourCoordinatorTests {
    @Test func catalogHasEightStepsWithUniqueIDs() {
        let steps = TourStep.allSteps
        #expect(steps.count == 8)
        #expect(Set(steps.map(\.id)).count == 8)
    }

    @Test func catalogHasSixSections() {
        let sectionStarts = TourStep.allSteps.filter { $0.tabIndex != nil }
        #expect(sectionStarts.count == 6)
        #expect(sectionStarts.map(\.tabIndex) == [0, 1, 2, 3, 4, 5])
    }

    private func makeCoordinator() -> TourCoordinator {
        let coordinator = TourCoordinator()
        coordinator.restart()
        return coordinator
    }

    @Test func restartActivatesAtStepZero() {
        let coordinator = makeCoordinator()
        #expect(coordinator.isActive == true)
        #expect(coordinator.currentStepIndex == 0)
        #expect(coordinator.currentStep?.id == "tabbar.today")
    }

    @Test func advanceMovesToNextStep() {
        let coordinator = makeCoordinator()
        coordinator.advance()
        #expect(coordinator.currentStep?.id == "tabbar.body")
    }

    @Test func advanceOnLastStepFinishes() {
        let coordinator = TourCoordinator(steps: [
            TourStep(id: "only", tabIndex: 0, title: "T", message: "M"),
        ])
        coordinator.restart()
        coordinator.advance()
        #expect(coordinator.isActive == false)
    }

    @Test func backStaysWithinASection() {
        let coordinator = makeCoordinator()
        coordinator.advance() // tabbar.body
        coordinator.advance() // bodymap.tapRegion
        coordinator.advance() // bodymap.findStretches
        coordinator.back()
        #expect(coordinator.currentStep?.id == "bodymap.tapRegion")
        coordinator.back()
        #expect(coordinator.currentStep?.id == "tabbar.body") // first step of the section — back() stops here
        coordinator.back()
        #expect(coordinator.currentStep?.id == "tabbar.body") // no-op past the section boundary
    }

    @Test func skipToNextSectionJumpsToNextTabsFirstStep() {
        let coordinator = makeCoordinator()
        coordinator.advance() // tabbar.body
        coordinator.skipToNextSection()
        #expect(coordinator.currentStep?.id == "tabbar.exercises")
    }

    @Test func skipFromLastSectionFinishesTheTour() {
        let coordinator = makeCoordinator()
        for _ in 0..<7 { coordinator.advance() } // walk to the last step, tabbar.profile
        coordinator.skipToNextSection()
        #expect(coordinator.isActive == false)
    }

    @Test func notifyInteractionAdvancesOnlyWhenIDMatchesTheCurrentInteractiveStep() {
        let coordinator = makeCoordinator()
        for _ in 0..<2 { coordinator.advance() } // land on bodymap.tapRegion
        #expect(coordinator.currentStep?.id == "bodymap.tapRegion")

        coordinator.notifyInteraction(id: "some.other.id")
        #expect(coordinator.currentStep?.id == "bodymap.tapRegion") // no-op: id doesn't match

        coordinator.notifyInteraction(id: "bodymap.tapRegion")
        #expect(coordinator.currentStep?.id == "bodymap.findStretches") // matches: advances
    }

    @Test func notifyInteractionIsNoOpOnANonInteractiveStep() {
        let coordinator = makeCoordinator() // tabbar.today — not interactive
        coordinator.notifyInteraction(id: "tabbar.today")
        #expect(coordinator.currentStep?.id == "tabbar.today")
    }

    @Test func notifyInteractionIsNoOpWhenTourIsInactive() {
        let coordinator = TourCoordinator()
        coordinator.notifyInteraction(id: "tabbar.today")
        #expect(coordinator.isActive == false)
    }

    @Test func restartFromAlreadyIndexZeroStillActivates() {
        let coordinator = TourCoordinator()
        #expect(coordinator.isActive == false)
        #expect(coordinator.currentStepIndex == 0)
        coordinator.restart()
        #expect(coordinator.isActive == true)
        #expect(coordinator.currentStepIndex == 0)
        #expect(coordinator.currentStep?.id == "tabbar.today")
    }

    @Test func onlyTheTwoBodyMapStepsAreInteractive() {
        let interactiveIDs = Set(TourStep.allSteps.filter(\.isInteractive).map(\.id))
        #expect(interactiveIDs == ["bodymap.tapRegion", "bodymap.findStretches"])
    }

    @Test func onlyTheTwoBodyMapStepsDisableBackgroundTapBlocking() {
        let nonBlockingIDs = Set(TourStep.allSteps.filter { !$0.blocksBackgroundTaps }.map(\.id))
        #expect(nonBlockingIDs == ["bodymap.tapRegion", "bodymap.findStretches"])
    }

    @Test func noStepHasFixedFrame() {
        let fixedFrameIDs = Set(TourStep.allSteps.filter { $0.fixedFrame != nil }.map(\.id))
        #expect(fixedFrameIDs.isEmpty)
    }
}
