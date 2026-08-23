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
        #expect(coordinator.currentStep?.id == "today.heroCard")
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
        coordinator.advance() // today.heroCard
        coordinator.advance() // today.recommended
        coordinator.back()
        #expect(coordinator.currentStep?.id == "today.heroCard")
        coordinator.back()
        #expect(coordinator.currentStep?.id == "tabbar.today") // first step of the section — back() stops here
        coordinator.back()
        #expect(coordinator.currentStep?.id == "tabbar.today") // no-op past the section boundary
    }

    @Test func skipToNextSectionJumpsToNextTabsFirstStep() {
        let coordinator = makeCoordinator()
        coordinator.advance() // today.heroCard
        coordinator.skipToNextSection()
        #expect(coordinator.currentStep?.id == "tabbar.body")
    }

    @Test func skipFromLastSectionFinishesTheTour() {
        let coordinator = makeCoordinator()
        for _ in 0..<18 { coordinator.advance() } // walk to the last step, profile.restartTour
        coordinator.skipToNextSection()
        #expect(coordinator.isActive == false)
    }

    @Test func notifyInteractionAdvancesOnlyWhenIDMatchesTheCurrentInteractiveStep() {
        let coordinator = makeCoordinator()
        for _ in 0..<4 { coordinator.advance() } // land on bodymap.tapMarkAndRegion
        #expect(coordinator.currentStep?.id == "bodymap.tapMarkAndRegion")

        coordinator.notifyInteraction(id: "some.other.id")
        #expect(coordinator.currentStep?.id == "bodymap.tapMarkAndRegion") // no-op: id doesn't match

        coordinator.notifyInteraction(id: "bodymap.tapMarkAndRegion")
        #expect(coordinator.currentStep?.id == "bodymap.confirmMark") // matches: advances
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
        #expect(interactiveIDs == ["bodymap.tapMarkAndRegion", "bodymap.confirmMark"])
    }

    @Test func onlyTheTwoBodyMapStepsDisableBackgroundTapBlocking() {
        let nonBlockingIDs = Set(TourStep.allSteps.filter { !$0.blocksBackgroundTaps }.map(\.id))
        #expect(nonBlockingIDs == ["bodymap.tapMarkAndRegion", "bodymap.confirmMark"])
    }

    @Test func onlyTheTwoToolbarStepsHaveFixedFrame() {
        let fixedFrameIDs = Set(TourStep.allSteps.filter { $0.fixedFrame != nil }.map(\.id))
        #expect(fixedFrameIDs == ["bodymap.confirmMark", "routines.createButton"])
    }
}
