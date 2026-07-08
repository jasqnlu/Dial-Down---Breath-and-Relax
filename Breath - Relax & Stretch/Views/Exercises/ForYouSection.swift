import SwiftUI

// MARK: - Exercise card

struct ForYouCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: exercise.type == .breath ? "wind" : "figure.mind.and.body")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor.opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(exercise.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(exercise.durationFormatted) · \(exercise.type.rawValue)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 128)
    }
}

// MARK: - Goal metadata

struct GoalMeta {
    let id: String
    let displayName: String
    let exerciseNames: [String]

    /// Interleaves exercises from each active goal so all goals contribute
    /// equally, deduped, up to `limit`. Shared by ForYouSection and the
    /// widget's quick-session deep link.
    static func recommend(from allExercises: [Exercise], activeGoalIDs: Set<String>, limit: Int) -> [Exercise] {
        let activeGoals = GoalMeta.all.filter { activeGoalIDs.contains($0.id) }
        guard !activeGoals.isEmpty else { return [] }
        let byName = Dictionary(grouping: allExercises, by: \.name).compactMapValues(\.first)

        var seen = Set<UUID>()
        var result: [Exercise] = []
        let goalLists = activeGoals.map { goal in
            goal.exerciseNames.compactMap { byName[$0] }
        }

        var index = 0
        while result.count < limit {
            var addedAny = false
            for list in goalLists where index < list.count {
                let ex = list[index]
                if seen.insert(ex.uuid).inserted {
                    result.append(ex)
                    addedAny = true
                }
            }
            if !addedAny { break }
            index += 1
        }
        return result
    }

    static let all: [GoalMeta] = [
        GoalMeta(
            id: "flexibility",
            displayName: "Flexibility",
            exerciseNames: [
                "Standing Hamstring Stretch",
                "Hip Flexor Stretch",
                "Standing Quad Stretch",
                "Seated Figure-Four Stretch",
                "Standing Side Stretch",
                "Cat-Cow Flow",
                "Seated Hamstring Stretch",
                "Figure-4 Glute Stretch",
            ]
        ),
        GoalMeta(
            id: "stress_relief",
            displayName: "Stress Relief",
            exerciseNames: [
                "Shoulder Roll",
                "Neck Side Stretch",
                "Seated Neck Rolls",
                "Eye Palming",
                "Child's Pose",
                "4-7-8 Breathing",
                "Alternate Nostril Breathing",
            ]
        ),
        GoalMeta(
            id: "pain_relief",
            displayName: "Pain Relief",
            exerciseNames: [
                "Cat-Cow Flow",
                "Child's Pose",
                "Knee-to-Chest Release",
                "Pelvic Tilt",
                "Glute Bridge",
                "Seated Spinal Twist",
                "Upper Back Cat-Cow",
                "Supine Knee-to-Chest",
            ]
        ),
        GoalMeta(
            id: "better_breathing",
            displayName: "Better Breathing",
            exerciseNames: [
                "Deep Belly Breath",
                "Box Breathing",
                "4-7-8 Breathing",
                "Diaphragmatic Breath with Counting",
                "Alternate Nostril Breathing",
                "Pursed Lip Breathing",
            ]
        ),
        GoalMeta(
            id: "wake_up",
            displayName: "Wake Up",
            exerciseNames: [
                "Box Breathing",
                "Cat-Cow Flow",
                "Shoulder Roll",
                "Standing Back Extension",
                "Doorway Shoulder & Chest Opener",
                "Seated Neck Rotation",
            ]
        ),
        GoalMeta(
            id: "unwind",
            displayName: "Unwind",
            exerciseNames: [
                "4-7-8 Breathing",
                "Deep Belly Breath",
                "Diaphragmatic Breath with Counting",
                "Child's Pose",
                "Happy Baby Pose",
                "Eye Palming",
            ]
        ),
    ]
}
