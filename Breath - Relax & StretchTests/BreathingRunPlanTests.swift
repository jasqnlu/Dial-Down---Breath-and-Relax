import Testing
@testable import BreathRelaxStretch

struct BreathingRunPlanTests {
    @Test func normalSessionUsesSelectedRoundsAndRecordsCompletion() {
        let plan = BreathingRunPlan.session(selectedRounds: 5)

        #expect(plan.totalRounds == 5)
        #expect(plan.recordsCompletion)
    }

    @Test func circlePreviewRunsOneRoundWithoutRecordingCompletion() {
        let plan = BreathingRunPlan.circlePreview(selectedRounds: 12)

        #expect(plan.totalRounds == 1)
        #expect(!plan.recordsCompletion)
    }
}
