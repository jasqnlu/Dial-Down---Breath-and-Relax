import Foundation

/// Pure filtering for ExercisePickerSheet: which exercises are still
/// available to add, given the ones already in the routine being built.
/// Matches by uuid (not object identity) so it's correct whether the
/// caller re-fetched Exercise instances or reused the same objects.
enum ExercisePickerCandidates {
    static func available(from all: [Exercise], excluding: [Exercise]) -> [Exercise] {
        let excludedIDs = Set(excluding.map(\.uuid))
        return all.filter { !excludedIDs.contains($0.uuid) }
    }
}
