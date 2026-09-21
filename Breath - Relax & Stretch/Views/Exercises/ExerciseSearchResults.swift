import Foundation

/// Coarse duration buckets for the Exercises tab filter sheet. Bucketed
/// rather than a raw numeric range picker — matches the low-friction,
/// tap-a-chip style of the existing type/difficulty filters, and exercise
/// durations cluster tightly enough (most are 30s-5m) that a handful of
/// named buckets covers the useful cases.
enum ExerciseDurationBucket: String, CaseIterable, Identifiable {
    case any = "Any"
    case under1Min = "Under 1 min"
    case oneToThreeMin = "1-3 min"
    case threePlusMin = "3+ min"

    var id: String { rawValue }

    func matches(_ seconds: Int) -> Bool {
        switch self {
        case .any: return true
        case .under1Min: return seconds < 60
        case .oneToThreeMin: return seconds >= 60 && seconds <= 180
        case .threePlusMin: return seconds > 180
        }
    }
}

struct ExerciseSearchResults {
    static let pageSize = 7

    let matches: [Exercise]
    let visibleCount: Int

    init(
        exercises: [Exercise],
        searchText: String,
        selectedType: ExerciseType?,
        visibleCount: Int,
        selectedDifficulties: Set<Int> = [],
        durationBucket: ExerciseDurationBucket = .any
    ) {
        let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.visibleCount = max(0, visibleCount)
        self.matches = exercises.filter { exercise in
            let matchesSearch = normalizedSearchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(normalizedSearchText)
                || exercise.localizedName().localizedCaseInsensitiveContains(normalizedSearchText)
                || exercise.type.rawValue.localizedCaseInsensitiveContains(normalizedSearchText)
                || exercise.targetBodyParts.contains {
                    $0.localizedCaseInsensitiveContains(normalizedSearchText)
                }
            let matchesType = selectedType == nil || exercise.type == selectedType
            let matchesDifficulty = selectedDifficulties.isEmpty || selectedDifficulties.contains(exercise.difficulty)
            let matchesDuration = durationBucket.matches(exercise.durationSeconds)
            return matchesSearch && matchesType && matchesDifficulty && matchesDuration
        }
    }

    var visible: [Exercise] {
        Array(matches.prefix(visibleCount))
    }

    var canLoadMore: Bool {
        visible.count < matches.count
    }

    var nextVisibleCount: Int {
        min(matches.count, visibleCount + Self.pageSize)
    }
}
