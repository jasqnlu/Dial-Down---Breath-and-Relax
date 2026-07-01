import Foundation

struct GamificationService {

    // MARK: - Points

    static func points(for exercise: Exercise?, completion: Double) -> Int {
        guard let exercise else { return 0 }
        let durationMinutes = Double(exercise.durationSeconds) / 60.0
        let difficultyMultiplier: Double = switch exercise.difficulty {
            case 1:  1.0
            case 2:  1.5
            case 3:  2.0
            default: 1.0
        }
        let completionBonus: Double = completion >= 1.0 ? 1.2 : completion >= 0.75 ? 1.0 : 0.7
        return max(1, Int(durationMinutes * difficultyMultiplier * completionBonus * 10))
    }

    /// Averages each exercise's individual completion into one session-wide
    /// value, instead of a session's completionPercent reflecting only
    /// whichever exercise happened to finish (or get skipped) last.
    static func aggregateCompletion(_ perExerciseCompletions: [Double]) -> Double {
        guard !perExerciseCompletions.isEmpty else { return 0 }
        return perExerciseCompletions.reduce(0, +) / Double(perExerciseCompletions.count)
    }

    // MARK: - Streak

    static func updateStreak(for profile: UserProfile) {
        let calendar = Calendar.current
        if let last = profile.lastSessionDate {
            if calendar.isDateInYesterday(last) {
                profile.streak += 1
            } else if !calendar.isDateInToday(last) {
                profile.streak = 1
            }
            // If already completed a session today, don't change streak
        } else {
            profile.streak = 1
        }
        profile.lastSessionDate = Date()
    }

    // MARK: - Badges

    /// Returns badges newly earned after a session.
    /// - Parameters:
    ///   - profile: The user profile to evaluate (already updated with this session's stats).
    ///   - bodyPartsCovered: Body parts targeted across all exercises in the session.
    static func newBadges(for profile: UserProfile, bodyPartsCovered: Set<String> = []) -> [String] {
        var new: [String] = []

        func award(_ badge: String) {
            if !profile.badges.contains(badge) { new.append(badge) }
        }

        award("First Breath")

        // Streak milestones
        if profile.streak >= 3  { award("Streak Starter") }
        if profile.streak >= 7  { award("Weekly Warrior") }
        if profile.streak >= 30 { award("Month of Mindfulness") }

        // Time milestones
        if profile.totalMinutes >= 30  { award("30 Min Club") }
        if profile.totalMinutes >= 60  { award("Hour Hero") }
        if profile.totalMinutes >= 300 { award("5 Hour Club") }

        // Points milestones
        if profile.totalPoints >= 100  { award("Century") }
        if profile.totalPoints >= 500  { award("High Achiever") }
        if profile.totalPoints >= 1000 { award("Elite Breather") }

        // Full body — session must touch 5+ distinct major muscle groups
        if !bodyPartsCovered.isEmpty {
            let majorGroups = ["Neck", "Shoulders", "Chest", "Back", "Core",
                               "Arms", "Forearm", "Legs", "Hips", "Glutes"]
            let coveredCount = majorGroups.filter { group in
                bodyPartsCovered.contains { $0.localizedCaseInsensitiveContains(group) }
            }.count
            if coveredCount >= 5 { award("Full Body") }
        }

        return new
    }

    /// Awards a single badge immediately (e.g. on first routine save).
    /// Returns true if the badge was newly applied; false if already earned.
    @discardableResult
    static func awardBadge(_ badge: String, to profile: UserProfile) -> Bool {
        guard !profile.badges.contains(badge) else { return false }
        profile.badges.append(badge)
        return true
    }

    static func applyBadges(_ badges: [String], to profile: UserProfile) {
        for badge in badges where !profile.badges.contains(badge) {
            profile.badges.append(badge)
        }
    }
}
