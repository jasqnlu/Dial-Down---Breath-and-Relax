import SwiftUI

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
    /// Both toolbar-hosted callouts (the body-map Confirm button and the
    /// Routines "+" button) render in `.primaryAction` placement, which iOS
    /// always docks top-trailing — so one shared fallback rect covers both.
    private static let toolbarPrimaryActionFrame: (GeometryProxy) -> CGRect = { proxy in
        CGRect(x: proxy.size.width - 60, y: proxy.safeAreaInsets.top + 4, width: 44, height: 40)
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
                 isInteractive: true),
        TourStep(id: "bodymap.confirmMark",
                 title: "Confirm It", message: "Tap the checkmark to confirm — if it asks you to pick between a couple of spots, tap the one you meant.",
                 isInteractive: true, fixedFrame: toolbarPrimaryActionFrame),
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
