import Foundation

/// Pure merge for adding freshly-picked exercise IDs onto a routine's
/// existing `exerciseIDs` (used when picking mode in the Exercises tab
/// feeds "Add to Existing Routine"). Mirrors `CustomizeRoutineExerciseMerge`
/// but operates on `[UUID]` directly since `RoutineBuilderView` tracks
/// selection as IDs, not resolved `Exercise` values.
enum RoutineIDMerge {
    static func appending(_ additions: [UUID], to base: [UUID]) -> [UUID] {
        var result = base
        var seenIDs = Set(base)
        for id in additions where !seenIDs.contains(id) {
            result.append(id)
            seenIDs.insert(id)
        }
        return result
    }
}
