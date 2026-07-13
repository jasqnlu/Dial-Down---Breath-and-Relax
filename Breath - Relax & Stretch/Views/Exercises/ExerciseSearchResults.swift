import Foundation

struct ExerciseSearchResults {
    static let pageSize = 7

    let matches: [Exercise]
    let visibleCount: Int

    init(
        exercises: [Exercise],
        searchText: String,
        selectedType: ExerciseType?,
        visibleCount: Int
    ) {
        let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.visibleCount = max(0, visibleCount)
        self.matches = exercises.filter { exercise in
            let matchesSearch = normalizedSearchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(normalizedSearchText)
                || exercise.type.rawValue.localizedCaseInsensitiveContains(normalizedSearchText)
                || exercise.targetBodyParts.contains {
                    $0.localizedCaseInsensitiveContains(normalizedSearchText)
                }
            let matchesType = selectedType == nil || exercise.type == selectedType
            return matchesSearch && matchesType
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
