import Testing
@testable import BreathRelaxStretch

struct SessionPlayerViewTests {

    // The 0.5x/1x/2x speed picker (and its `scaledDuration` scaling helper)
    // was removed in favor of letting users set exercise duration directly
    // via Customize's duration stepper — see `upNextLeadSeconds` below for
    // its replacement in the player's top bar.
    @Test func upNextLeadSecondsMatchesDesignedPreviewWindow() {
        #expect(SessionPlayerView.upNextLeadSeconds == 5)
    }
}
