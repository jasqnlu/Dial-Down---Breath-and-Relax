import Foundation
import Combine

/// Cross-tab picking state for CustomizeRoutineView's "Add Exercises" flow.
/// Unlike `DeepLinkAction` (a one-shot `Identifiable` enum driven through
/// `.sheet(item:)`), this is persistent and mutated by taps arbitrarily
/// deep inside the Exercises tab across any number of tab switches — so it
/// gets its own environment object, injected app-wide alongside
/// `DeepLinkRouter`/`AuthManager`, rather than overloading `DeepLinkAction`.
final class ExercisePickingSession: ObservableObject {
    /// Snapshot of the routine being built, captured when "Add Exercises"
    /// starts a session — carried through the tab switch so Done can
    /// re-present Customize exactly as the user left it, plus the picks.
    struct Context {
        let title: String
        let isPinned: Bool
        let baseExercises: [Exercise]
        /// Which HomeView tab index started this picking session — read by
        /// HomeView's `.exercisePickingFinished` handler so it returns to
        /// whichever tab is actually waiting to re-present its sheet, not
        /// always Home. CustomizeRoutineView always passes 0 (Today); the
        /// RoutineBuilderView call site (Routines tab) passes 4.
        let originTab: Int
        /// The Routine being edited when picking started, if any — nil for
        /// a brand-new routine (or for CustomizeRoutineView, which has no
        /// underlying Routine at all until it's pinned). Carried through so
        /// RoutineListView can tell "update" from "create" apart after the
        /// cross-tab round trip.
        let editingRoutineID: UUID?
        /// Per-exercise duration overrides already set on the routine
        /// before picking started, keyed by exercise UUID — carried
        /// through so re-presenting the routine builder doesn't silently
        /// discard custom durations already set on exercises already in
        /// the list. Always empty for CustomizeRoutineView, which doesn't
        /// support duration overrides.
        let durationOverrides: [UUID: Int]
    }

    struct FinishedResult {
        let context: Context
        let merged: [Exercise]
    }

    @Published private(set) var isActive = false
    @Published private(set) var picked: [Exercise] = []
    private var context: Context?

    /// True when this session was started from Customize's "Add Exercises"
    /// (via `begin(context:)`) rather than standalone from the Exercises
    /// tab's own "Select" button (via `begin()`). `PickingBar` reads this to
    /// decide whether its action button merges into Customize ("Done") or
    /// opens the mini-routine review screen ("Continue").
    var hasContext: Bool { context != nil }

    /// Set by `finish()`, read (once) by whoever re-presents Customize
    /// after the `.exercisePickingFinished` notification — kept separate
    /// from `isActive`/`picked` (which are cleared by `finish()`) so a
    /// listener that reacts to the notification a beat later still has
    /// something to read.
    @Published private(set) var lastFinished: FinishedResult?
    /// The origin tab of the most recent `finish()` — set alongside
    /// `lastFinished` but NEVER cleared by `consumeFinished()`. HomeView's
    /// tab-switch handler reads this instead of `lastFinished?.context
    /// .originTab`, because NotificationCenter delivery order across
    /// sibling `.onReceive` subscribers on the same notification is not
    /// guaranteed — if the destination screen's own handler happens to
    /// consume (and thus nil out) `lastFinished` before HomeView's handler
    /// runs, a read of `lastFinished` here would silently fail and skip
    /// the tab switch. This value is safe to leave stale between finishes;
    /// it's only ever read reactively from the same notification that set
    /// it, and the next `finish()` always overwrites it before the next
    /// notification fires.
    @Published private(set) var lastFinishedOriginTab: Int?

    func begin(context: Context) {
        self.context = context
        picked = []
        isActive = true
    }

    /// Starts picking with no Customize context — entered from the
    /// Exercises tab's own "Select" toolbar button. `finish()` is a no-op
    /// for this session (there's nothing to merge into); the caller reads
    /// `picked` directly once picking wraps up via the review screen.
    func begin() {
        context = nil
        picked = []
        isActive = true
    }

    func toggle(_ exercise: Exercise) {
        if let index = picked.firstIndex(where: { $0.uuid == exercise.uuid }) {
            picked.remove(at: index)
        } else {
            picked.append(exercise)
        }
    }

    func isPicked(_ exercise: Exercise) -> Bool {
        picked.contains { $0.uuid == exercise.uuid }
    }

    var pickedTotalSeconds: Int {
        picked.reduce(0) { $0 + $1.durationSeconds }
    }

    @discardableResult
    func finish() -> FinishedResult? {
        guard let context else { return nil }
        let merged = CustomizeRoutineExerciseMerge.appending(picked, to: context.baseExercises)
        let result = FinishedResult(context: context, merged: merged)
        lastFinished = result
        lastFinishedOriginTab = context.originTab
        isActive = false
        picked = []
        self.context = nil
        return result
    }

    func consumeFinished() -> FinishedResult? {
        defer { lastFinished = nil }
        return lastFinished
    }

    /// Not yet wired to any UI affordance — reserved for a future
    /// "cancel picking" control. Intentionally kept (and unit-tested) rather
    /// than removed as dead code.
    func cancel() {
        isActive = false
        picked = []
        context = nil
    }
}
