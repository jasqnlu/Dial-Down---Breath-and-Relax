import SwiftUI
import Combine

/// One stop on the coach-mark tour. `id` matches a `.tourAnchor(id:)` tag
/// on the real view being called out (or is used purely as a lookup key
/// for `fixedFrame` steps, which skip anchor tracking entirely — see the
/// spec's "Toolbar items" section for why).
struct TourStep: Identifiable {
    let id: String
    /// Which `HomeView` tab this step needs. `nil` means "stay on whatever
    /// tab the previous step left us on" — every section's first step
    /// carries a tabIndex, no other step does.
    let tabIndex: Int?
    let title: String
    let message: String
    /// True only for the two body-map steps, which wait for a real tap
    /// instead of a Next button.
    let isInteractive: Bool
    /// Screen-relative fallback for a toolbar-hosted callout, where
    /// `.tourAnchor` can't cross the `NavigationStack` → `UINavigationController`
    /// boundary reliably. No current step needs this (the tour is anchor-only
    /// now), but the mechanism stays available for a future toolbar callout.
    let fixedFrame: ((GeometryProxy) -> CGRect)?

    init(id: String, tabIndex: Int? = nil, title: String, message: String,
         isInteractive: Bool = false, fixedFrame: ((GeometryProxy) -> CGRect)? = nil) {
        self.id = id
        self.tabIndex = tabIndex
        self.title = title
        self.message = message
        self.isInteractive = isInteractive
        self.fixedFrame = fixedFrame
    }
}

extension TourStep: Equatable {
    // Closures aren't Equatable — steps are uniquely identified by id anyway,
    // so equality only needs to compare that.
    static func == (lhs: TourStep, rhs: TourStep) -> Bool { lhs.id == rhs.id }
}

extension TourStep {
    /// A light, one-step-per-section overview: each tab gets a single
    /// callout on arrival, except Body, which keeps a short interactive
    /// walkthrough (tap-to-advance) since that's the one flow worth
    /// teaching by doing rather than telling.
    static let allSteps: [TourStep] = [
        // MARK: Today
        TourStep(id: "tabbar.today", tabIndex: 0,
                 title: "Today", message: "Start here each day. Your picked routine is ready, or browse more below."),

        // MARK: Body
        TourStep(id: "bodymap.tapRegion", tabIndex: 1,
                 title: "Tap a Sore Spot", message: "Tap anywhere that feels tense or sore — the body turns to face it.",
                 isInteractive: true),
        TourStep(id: "bodymap.findStretches",
                 title: "Find Stretches", message: "Tap here for stretches that target it. Double-tap the body instead to pick an exact muscle.",
                 isInteractive: true),

        // MARK: Exercises
        TourStep(id: "tabbar.exercises", tabIndex: 2,
                 title: "Exercises", message: "Browse the full library, search by name, or explore by body region."),

        // MARK: Breathe
        TourStep(id: "tabbar.breathe", tabIndex: 3,
                 title: "Breathe", message: "Guided patterns — pick one, then preview or start a full session."),

        // MARK: Routines
        TourStep(id: "tabbar.routines", tabIndex: 4,
                 title: "Routines", message: "Build your own routines or borrow ready-made ones."),

        // MARK: Profile
        TourStep(id: "tabbar.profile", tabIndex: 5,
                 title: "Profile", message: "Track your stats, and restart this tour anytime from here."),
    ]
}

/// Drives the coach-mark tour: which step is current, and how
/// Back/Next/Skip/Restart move through the step catalog. Pure state —
/// `TourSpotlightOverlay` renders whatever `currentStep` says, and
/// `HomeView`/`ProfileView` read it to drive their own tab state.
final class TourCoordinator: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var currentStepIndex = 0

    let steps: [TourStep]

    init(steps: [TourStep] = TourStep.allSteps) {
        self.steps = steps
    }

    var currentStep: TourStep? {
        steps.indices.contains(currentStepIndex) ? steps[currentStepIndex] : nil
    }

    var stepNumber: Int { currentStepIndex + 1 }
    var totalSteps: Int { steps.count }

    /// True on the first step of the tour, or any step that switches tabs —
    /// `back()` refuses to walk past this, so it never re-triggers a
    /// backward tab switch.
    var isFirstStepInSection: Bool {
        guard currentStepIndex > 0 else { return true }
        return steps[currentStepIndex].tabIndex != nil
    }

    func restart() {
        currentStepIndex = 0
        isActive = true
    }

    func advance() {
        guard isActive else { return }
        if currentStepIndex >= steps.count - 1 {
            finish()
        } else {
            currentStepIndex += 1
        }
    }

    func back() {
        guard isActive, !isFirstStepInSection else { return }
        currentStepIndex -= 1
    }

    /// Jumps to the next section's first step (the next step with a
    /// non-nil tabIndex different from the current section's), or finishes
    /// the tour if already in the last section.
    func skipToNextSection() {
        guard isActive else { return }
        let currentTab = sectionTab(atOrBefore: currentStepIndex)
        let remaining = steps[(currentStepIndex + 1)...]
        if let nextIndex = remaining.firstIndex(where: { $0.tabIndex != nil && $0.tabIndex != currentTab }) {
            currentStepIndex = nextIndex
        } else {
            finish()
        }
    }

    func finish() {
        isActive = false
    }

    /// Real views call this when the user performs the action an
    /// interactive step is waiting for. No-op unless the current step is
    /// interactive and its id matches — so a stray call from an unrelated
    /// screen, or a call after the tour already moved on, does nothing.
    func notifyInteraction(id: String) {
        guard isActive, let step = currentStep, step.isInteractive, step.id == id else { return }
        advance()
    }

    /// Walks backward from `index` to the most recent step that declared a
    /// tabIndex — needed because most steps in a section (including both
    /// interactive body-map steps) carry `tabIndex == nil`.
    private func sectionTab(atOrBefore index: Int) -> Int? {
        for i in stride(from: index, through: 0, by: -1) {
            if let tab = steps[i].tabIndex { return tab }
        }
        return nil
    }
}
