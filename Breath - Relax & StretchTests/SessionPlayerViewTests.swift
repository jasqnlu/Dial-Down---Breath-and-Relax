import Testing
@testable import BreathRelaxStretch

struct SessionPlayerViewTests {

    @Test func scaledDurationAppliesMultiplier() {
        #expect(SessionPlayerView.scaledDuration(base: 60, multiplier: 1.0) == 60)
        #expect(SessionPlayerView.scaledDuration(base: 60, multiplier: 0.5) == 30)
        #expect(SessionPlayerView.scaledDuration(base: 60, multiplier: 2.0) == 120)
    }

    @Test func scaledDurationNeverDropsBelowOneSecond() {
        #expect(SessionPlayerView.scaledDuration(base: 1, multiplier: 0.5) == 1)
    }
}
