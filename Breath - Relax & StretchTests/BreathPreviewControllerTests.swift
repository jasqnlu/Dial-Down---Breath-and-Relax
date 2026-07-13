import Testing
import Combine
@testable import BreathRelaxStretch

@MainActor struct BreathPreviewControllerTests {
    @Test func playsOneFullCycleThenIdles() async throws {
        let c = BreathPreviewController(timeScale: 0.01)   // 4-7-8 → ~190ms total (phases (4,7,8,0))
        c.toggle(pattern: .fourSevenEight)
        #expect(c.state == .playing(.inhale))
        try await Task.sleep(for: .milliseconds(400))
        #expect(c.state == .idle)
    }

    @Test func secondToggleCancels() async throws {
        let c = BreathPreviewController(timeScale: 0.01)
        c.toggle(pattern: .box)
        c.toggle(pattern: .box)
        #expect(c.state == .idle)
    }

    @Test func zeroHoldPhasesAreSkipped() async throws {
        // Pattern with hold == 0 must go inhale → exhale without a .hold state.
        let c = BreathPreviewController(timeScale: 0.01)
        var seen: [BreathPreviewController.State] = []
        let obs = c.$state.sink { seen.append($0) }
        c.toggle(pattern: .energising)   // phases (6, 0, 2, 0) — hold and hold2 are both 0
        try await Task.sleep(for: .milliseconds(300))
        _ = obs
        #expect(!seen.contains(.playing(.hold)))
        #expect(!seen.contains(.playing(.hold2)))
        #expect(seen.contains(.playing(.exhale)))
    }
}
