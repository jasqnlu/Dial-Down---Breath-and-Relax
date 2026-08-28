import Testing
@testable import BreathRelaxStretch

struct BreathPhaseCycleTests {
    private let boxBreathing = [
        BreathPhaseStep(label: "Inhale", seconds: 4),
        BreathPhaseStep(label: "Hold", seconds: 4),
        BreathPhaseStep(label: "Exhale", seconds: 4),
        BreathPhaseStep(label: "Hold", seconds: 4),
    ]

    @Test func emptyPatternResolvesToNil() {
        #expect(BreathPhaseCycle.resolve(pattern: [], elapsedSeconds: 0) == nil)
    }

    @Test func firstTickIsFirstPhaseAtFullDuration() {
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 0)
        #expect(resolved == .init(phaseIndex: 0, secondsRemainingInPhase: 4))
    }

    @Test func oneSecondIntoFirstPhase() {
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 1)
        #expect(resolved == .init(phaseIndex: 0, secondsRemainingInPhase: 3))
    }

    @Test func exactBoundaryLandsOnNextPhase() {
        // 4 seconds elapsed = exactly the end of phase 0 (Inhale) = start of phase 1 (Hold).
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 4)
        #expect(resolved == .init(phaseIndex: 1, secondsRemainingInPhase: 4))
    }

    @Test func midwayThroughThirdPhase() {
        // 4 (Inhale) + 4 (Hold) + 2 = 2 seconds into Exhale (index 2), 2 remaining.
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 10)
        #expect(resolved == .init(phaseIndex: 2, secondsRemainingInPhase: 2))
    }

    @Test func wrapsAroundAfterFullCycle() {
        // Box Breathing's cycle is 16s total; 16 seconds elapsed wraps back to phase 0.
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 16)
        #expect(resolved == .init(phaseIndex: 0, secondsRemainingInPhase: 4))
    }

    @Test func wrapsAroundMidwaySecondCycle() {
        // 16 (one full cycle) + 10 = same offset as midwayThroughThirdPhase.
        let resolved = BreathPhaseCycle.resolve(pattern: boxBreathing, elapsedSeconds: 26)
        #expect(resolved == .init(phaseIndex: 2, secondsRemainingInPhase: 2))
    }

    @Test func singlePhasePattern() {
        let pattern = [BreathPhaseStep(label: "Breathe", seconds: 5)]
        #expect(BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 0) == .init(phaseIndex: 0, secondsRemainingInPhase: 5))
        #expect(BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 3) == .init(phaseIndex: 0, secondsRemainingInPhase: 2))
        #expect(BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 5) == .init(phaseIndex: 0, secondsRemainingInPhase: 5))
    }

    @Test func patternWithAZeroSecondPhaseIsSkippedOver() {
        // Defensive: a malformed 0-second phase should never be selected as
        // the resolved phase (would show "· 0" forever) — resolve steps past it.
        let pattern = [
            BreathPhaseStep(label: "Inhale", seconds: 4),
            BreathPhaseStep(label: "Glitch", seconds: 0),
            BreathPhaseStep(label: "Exhale", seconds: 4),
        ]
        let resolved = BreathPhaseCycle.resolve(pattern: pattern, elapsedSeconds: 4)
        #expect(resolved?.phaseIndex == 2)
    }
}
