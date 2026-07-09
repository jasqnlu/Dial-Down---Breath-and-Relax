import Foundation

struct ExerciseGraphGroup: Identifiable {
    let title: String
    let exercises: [Exercise]

    var id: String { title }
}

enum ExerciseGraphGrouping {
    static func groups(for exercises: [Exercise], in category: ExerciseCategory) -> [ExerciseGraphGroup] {
        if category == .chest {
            return chestGroups(for: exercises)
        }

        let categoryParts = exercises.flatMap { exercise in
            exercise.targetBodyParts.filter { ExerciseCategory.categories(for: [$0]).contains(category) }
        }
        let preferredParts = Set(categoryParts)

        var buckets: [String: [Exercise]] = [:]
        for exercise in exercises {
            let matchingParts = exercise.targetBodyParts.filter { preferredParts.contains($0) }
            let key = displayTitle(for: matchingParts.first ?? difficultyGroup(for: exercise.difficulty))
            buckets[key, default: []].append(exercise)
        }

        return buckets
            .map { ExerciseGraphGroup(title: $0.key, exercises: $0.value.sorted { $0.name < $1.name }) }
            .sorted {
                if $0.exercises.count == $1.exercises.count {
                    return $0.title < $1.title
                }
                return $0.exercises.count > $1.exercises.count
            }
    }

    private static func chestGroups(for exercises: [Exercise]) -> [ExerciseGraphGroup] {
        groupedExercises(exercises) { exercise in
            let name = exercise.name.lowercased()
            if name.contains("minor") || name.contains("corner") {
                return "Pectoralis Minor"
            }
            if name.contains("chest") || name.contains("pec") {
                return "Pectoralis Major"
            }
            return "General Chest"
        }
    }

    private static func groupedExercises(_ exercises: [Exercise],
                                         key: (Exercise) -> String) -> [ExerciseGraphGroup] {
        var buckets: [String: [Exercise]] = [:]
        for exercise in exercises {
            buckets[key(exercise), default: []].append(exercise)
        }
        return buckets
            .map { ExerciseGraphGroup(title: $0.key, exercises: $0.value.sorted { $0.name < $1.name }) }
            .sorted {
                if $0.exercises.count == $1.exercises.count {
                    return $0.title < $1.title
                }
                return $0.exercises.count > $1.exercises.count
            }
    }

    private static func displayTitle(for rawValue: String) -> String {
        rawValue
            .replacingOccurrences(of: "Left ", with: "")
            .replacingOccurrences(of: "Right ", with: "")
    }

    private static func difficultyGroup(for difficulty: Int) -> String {
        switch difficulty {
        case ...1: return "Beginner"
        case 2: return "Intermediate"
        default: return "Advanced"
        }
    }
}
