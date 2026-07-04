import SwiftUI

// MARK: - For You Section

struct ForYouSection: View {
    let allExercises: [Exercise]

    @AppStorage("onboardingGoals") private var goalsStr = ""
    @State private var showingSession = false

    private var activeGoals: [GoalMeta] {
        let ids = Set(goalsStr.split(separator: ",").map(String.init))
        return GoalMeta.all.filter { ids.contains($0.id) }
    }

    private var recommendedExercises: [Exercise] {
        GoalMeta.recommend(from: allExercises, activeGoalIDs: Set(goalsStr.split(separator: ",").map(String.init)), limit: 8)
    }

    private var sessionExercises: [Exercise] {
        Array(recommendedExercises.prefix(4))
    }

    var body: some View {
        if !activeGoals.isEmpty, !recommendedExercises.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                exerciseCards

                if !sessionExercises.isEmpty {
                    quickSessionButton
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                Divider()
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
            }
            .sheet(isPresented: $showingSession) {
                SessionPlayerView(exercises: sessionExercises)
            }
        }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("For You")
                    .font(.title2.bold())
                Text(activeGoals.map(\.displayName).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: Cards

    private var exerciseCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(recommendedExercises) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        ForYouCard(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
    }

    // MARK: Quick session

    private var quickSessionButton: some View {
        let totalSecs = sessionExercises.reduce(0) { $0 + $1.durationSeconds }
        let mins = max(1, totalSecs / 60)

        return Button {
            showingSession = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.subheadline)

                Text("Quick Session")
                    .fontWeight(.semibold)

                Spacer()

                Text("\(sessionExercises.count) exercises · \(mins)m")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick session: \(sessionExercises.count) exercises, \(mins) minutes")
    }
}

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
    ]
}
