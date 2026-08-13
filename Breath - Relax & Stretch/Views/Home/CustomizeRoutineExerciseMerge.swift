import Foundation

/// Pure merge for CustomizeRoutineView's "Add Exercises" flow: appends
/// newly picked exercises after the existing routine, skipping any that
/// (defensively) are already present — ExercisePickerSheet's own excluding
/// list should prevent duplicates reaching here, but matching by uuid
/// keeps this correct even if that guarantee ever slips.
enum CustomizeRoutineExerciseMerge {
    static func appending(_ additions: [Exercise], to base: [Exercise]) -> [Exercise] {
        var result = base
        var seenIDs = Set(base.map(\.uuid))
        for exercise in additions where !seenIDs.contains(exercise.uuid) {
            result.append(exercise)
            seenIDs.insert(exercise.uuid)
        }
        return result
    }
}
