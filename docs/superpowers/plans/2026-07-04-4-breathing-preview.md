# Breathing Circle Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tapping the idle breathing circle plays ONE silent demo cycle of the selected pattern's animation, then settles back to idle.

**Architecture:** A small `BreathPreviewController` state machine (extracted, testable) drives the same `circleScale`/`circleColor`/phase-label state the live session uses; `BreathingView` owns one and forwards its published phase into the existing animation modifiers. No session record, no haptics, no `VoiceCueService`.

**Tech Stack:** SwiftUI, Swift Concurrency (`Task.sleep`), Swift Testing.

## Global Constraints

- Branch: `feature/breathing-preview`, cut from `main` (independent).
- Preview must be interruptible: tapping again OR pressing Start cancels instantly and restores idle scale 1.0.
- `BreathingPattern.phases` tuple `(inhale, hold, exhale, hold2)` in `Views/Breathing/BreathingModels.swift` is the timing source.
- Test command: `xcodebuild test -project "Breath - Relax & Stretch.xcodeproj" -scheme BreathRelaxStretch -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"Breath - Relax & StretchTests"`

---

### Task 1: BreathPreviewController state machine

**Files:**
- Create: `Views/Breathing/BreathPreviewController.swift`
- Test: `Breath - Relax & StretchTests/BreathPreviewControllerTests.swift`

**Interfaces:**
- Produces:

```swift
@MainActor final class BreathPreviewController: ObservableObject {
    enum State: Equatable { case idle, playing(BreathPhase) }
    @Published private(set) var state: State = .idle
    /// Speed multiplier so tests run in milliseconds (1.0 in the app).
    init(timeScale: Double = 1.0)
    func toggle(pattern: BreathingPattern)   // idle→play one cycle; playing→cancel
    func cancel()
}
```

- Phase sequence for one cycle: `.inhale` (inhale s) → `.hold` (hold s, skipped when 0) → `.exhale` (exhale s) → `.hold2` (hold2 s, skipped when 0) → `.idle`. Implemented as one cancellable `Task` using `try await Task.sleep(for: .seconds(duration * timeScale))`.

- [ ] **Step 1: Failing tests**

```swift
import Testing
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
```

(Pattern cases verified against `BreathingModels.swift`: `.box (4,4,4,4)`, `.fourSevenEight (4,7,8,0)`, `.belly (4,1,6,0)`, `.energising (6,0,2,0)`, `.custom`. Import Combine for `.sink`. The zero-hold test must also expect no `.playing(.hold2)`.)

- [ ] **Step 2: Run — FAIL.**
- [ ] **Step 3: Implement** (store the running `Task<Void, Never>`; `cancel()` cancels it and sets `.idle`; each phase sets `state = .playing(phase)` then sleeps; `Task.isCancelled` checks between phases; final `state = .idle`).
- [ ] **Step 4: Run — PASS. Commit** `git commit -m "feat: breathing preview state machine"`

---

### Task 2: Wire into BreathingView

**Files:**
- Modify: `Views/Breathing/BreathingView.swift`

**Interfaces:**
- Consumes: `BreathPreviewController` (Task 1).

Changes (all inside `BreathingView`):
1. `@StateObject private var preview = BreathPreviewController()`.
2. Circle `ZStack` gets `.onTapGesture { guard !isRunning else { return }; preview.toggle(pattern: selectedPattern) }` plus `.accessibilityHint("Plays a preview of the breathing rhythm")`.
3. Drive animation from preview when idle-previewing: `.onChange(of: preview.state)` — on `.playing(let phase)`: set `circleScale` (inhale → 1.35, exhale → 1.0, holds keep current) and `circleColor = phase.color`; on `.idle`: `circleScale = 1.0`, `circleColor = selectedPattern`-appropriate idle color (whatever the current idle assignment is — reuse the existing reset done in `stopSession()`).
4. Reuse `circleAnimation` durations: extend that computed property to consult `preview.state`'s phase when not running.
5. Phase label: when `case .playing(let phase) = preview.state`, show `phase.displayLabel` in the label slot with a trailing `"Preview"` caption badge; keep the pattern description otherwise.
6. Idle hint: under the description, `Text("Tap the circle to preview")` `.font(.caption2)` `.foregroundStyle(.tertiary)` — hidden while previewing.
7. `handleStartPause()` first line: `preview.cancel()`. Pattern card selection (`patternCard`) also calls `preview.cancel()` before switching.

- [ ] **Step 1:** Implement the wiring.
- [ ] **Step 2:** Build + full suite — green.
- [ ] **Step 3:** Simulator: tap circle on Box pattern; verify expansion/contraction cycle + label; tap Start mid-preview → session starts cleanly from scale 1.0. Screenshot mid-inhale.
- [ ] **Step 4: Commit** `git commit -m "feat: tap breathing circle to preview the pattern"`
