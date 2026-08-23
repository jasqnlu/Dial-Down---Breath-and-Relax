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
    /// Screen-relative fallback for the two toolbar-hosted callouts, where
    /// `.tourAnchor` can't cross the `NavigationStack` → `UINavigationController`
    /// boundary reliably. `nil` for every other step, which uses real anchor
    /// tracking instead.
    let fixedFrame: ((GeometryProxy) -> CGRect)?
    /// Whether the dim layer's Path should hit-test at all for this step.
    /// `true` (the default) for every ordinary step — the dim layer blocks
    /// taps outside its cutout, same as before. `false` is an escape hatch
    /// for a step whose interaction can land on more than one real target,
    /// which the current one-rect-per-step design can't represent as a
    /// single cutout:
    /// - `bodymap.tapMarkAndRegion` needs the toolbar Mark button tapped
    ///   first, then the body.
    /// - `bodymap.confirmMark` needs the toolbar checkmark tapped, but a
    ///   tap that's ambiguous between a couple of marked regions opens a
    ///   disambiguation candidate list that can render anywhere on screen
    ///   (wherever the user tapped the body earlier) — nowhere near the
    ///   checkmark's small `fixedFrame` cutout.
    /// When `false`, the dim layer stops intercepting taps everywhere on
    /// screen, letting all of them pass through to the real app underneath;
    /// the tooltip card itself is unaffected and keeps its own hit-testing.
    let blocksBackgroundTaps: Bool

    init(id: String, tabIndex: Int? = nil, title: String, message: String,
         isInteractive: Bool = false, fixedFrame: ((GeometryProxy) -> CGRect)? = nil,
         blocksBackgroundTaps: Bool = true) {
        self.id = id
        self.tabIndex = tabIndex
        self.title = title
        self.message = message
        self.isInteractive = isInteractive
        self.fixedFrame = fixedFrame
        self.blocksBackgroundTaps = blocksBackgroundTaps
    }
}

extension TourStep: Equatable {
    // Closures aren't Equatable — steps are uniquely identified by id anyway,
    // so equality only needs to compare that.
    static func == (lhs: TourStep, rhs: TourStep) -> Bool { lhs.id == rhs.id }
}

extension TourStep {
    /// Both toolbar-hosted callouts (the body-map Confirm button and the
    /// Routines "+" button) render in `.primaryAction` placement, which iOS
    /// always docks top-trailing — so one shared fallback rect covers both.
    ///
    /// Deliberately does NOT use `proxy.safeAreaInsets.top`: the
    /// `GeometryProxy` this closure receives comes from a `GeometryReader`
    /// that sits under `.ignoresSafeArea()` in `HomeView` (so the dim
    /// overlay itself can paint edge-to-edge). That makes the reader report
    /// its OWN safe-area insets as zero, not the device's real value —
    /// confirmed by direct instrumentation: `proxy.safeAreaInsets.top`
    /// measured 0 on a device whose real top inset is ~59pt, so the old
    /// `y: proxy.safeAreaInsets.top + 4` placed this rect (and therefore the
    /// dim layer's cutout) roughly 60pt too high — nowhere near the real
    /// toolbar button, which is why it was never actually tappable through
    /// the overlay despite `fixedFrame` "looking" correct on paper. Reading
    /// the key window's safe area directly via UIKit sidesteps that.
    private static var deviceSafeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 59
    }

    private static let toolbarPrimaryActionFrame: (GeometryProxy) -> CGRect = { proxy in
        CGRect(x: proxy.size.width - 60, y: deviceSafeAreaTop + 4, width: 44, height: 40)
    }

    static let allSteps: [TourStep] = [
        // MARK: Today
        TourStep(id: "tabbar.today", tabIndex: 0,
                 title: "Today", message: "Start here each day — this is your Today tab."),
        TourStep(id: "today.heroCard",
                 title: "Today's Session", message: "Your picked routine for right now. Customize it or tap Begin to start."),
        TourStep(id: "today.recommended",
                 title: "Recommended for You", message: "More routines picked from your goals — swipe through for other options."),

        // MARK: Body
        TourStep(id: "tabbar.body", tabIndex: 1,
                 title: "Body", message: "Rotate the body and tap an area that's bothering you."),
        TourStep(id: "bodymap.tapMarkAndRegion",
                 title: "Mark a Spot", message: "Tap Mark up top, then tap a spot on the body that feels tense or sore.",
                 isInteractive: true, blocksBackgroundTaps: false),
        TourStep(id: "bodymap.confirmMark",
                 title: "Confirm It", message: "Tap the checkmark to confirm — if it asks you to pick between a couple of spots, tap the one you meant.",
                 isInteractive: true, fixedFrame: toolbarPrimaryActionFrame, blocksBackgroundTaps: false),
        TourStep(id: "bodymap.regionResults",
                 title: "Exercises for This Spot", message: "Here's everything that targets the area you picked."),

        // MARK: Exercises
        TourStep(id: "tabbar.exercises", tabIndex: 2,
                 title: "Exercises", message: "Browse the full library any time."),
        TourStep(id: "exercises.search",
                 title: "Search", message: "Search by name, or filter by type with the icon next to it."),
        TourStep(id: "exercises.browseByArea",
                 title: "Browse by Area", message: "Or explore the map below — grouped by body region."),

        // MARK: Breathe
        TourStep(id: "tabbar.breathe", tabIndex: 3,
                 title: "Breathe", message: "Guided breathing patterns, any time you need to reset."),
        TourStep(id: "breathe.patternPicker",
                 title: "Pick a Pattern", message: "Choose the pattern that fits how you're feeling."),
        TourStep(id: "breathe.previewCircle",
                 title: "Preview or Begin", message: "Tap the circle for a one-round preview, or use the controls below to start a full session."),

        // MARK: Routines
        TourStep(id: "tabbar.routines", tabIndex: 4,
                 title: "Routines", message: "Build your own routines or borrow ready-made ones."),
        TourStep(id: "routines.sharedList",
                 title: "Premade Routines", message: "Start from a ready-made routine built around a goal."),
        TourStep(id: "routines.createButton",
                 title: "Create Your Own", message: "Tap + to build a routine from your favorite exercises.",
                 fixedFrame: toolbarPrimaryActionFrame),

        // MARK: Profile
        TourStep(id: "tabbar.profile", tabIndex: 5,
                 title: "Profile", message: "Track your progress and manage settings here."),
        TourStep(id: "profile.stats",
                 title: "Your Stats", message: "Streaks, points, and badges — a running record of your practice."),
        TourStep(id: "profile.restartTour",
                 title: "Come Back Anytime", message: "Restart this tour whenever you like from here. That's the tour — enjoy!"),
    ]
}

/// Drives the coach-mark tour: which step is current, and how
/// Back/Next/Skip/Restart move through the 19-step catalog. Pure state —
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
