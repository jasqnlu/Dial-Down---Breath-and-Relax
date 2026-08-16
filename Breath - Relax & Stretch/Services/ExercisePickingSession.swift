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
