import Foundation

struct GamificationService {

    // MARK: - Points

    /// Calculate points earned for completing an exercise.
    /// - Parameters:
    ///   - exercise: The exercise that was performed.
    ///   - completion: Fraction completed (0.0 – 1.0). 1.0 = full, 0.5 = skipped.
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

    // MARK: - Streak

    /// Updates the streak on a profile based on today's date.
    /// Call this once per completed session.
    static func updateStreak(for profile: UserProfile) {
        let calendar = Calendar.current
        if let last = profile.lastSessionDate {
            if calendar.isDateInYesterday(last) {
                profile.streak += 1
            } else if !calendar.isDateInToday(last) {
                profile.streak = 1  // streak broken — reset
            }
            // If already completed a session today, don't change streak
        } else {
            profile.streak = 1
        }
        profile.lastSessionDate = Date()
    }

    // MARK: - Badges

    /// Returns any new badges the profile should receive after a session.
    static func newBadges(for profile: UserProfile) -> [String] {
        var new: [String] = []

        func award(_ badge: String) {
            if !profile.badges.contains(badge) {
                new.append(badge)
            }
        }

        award("First Breath")   // always awarded on first session

        if profile.streak >= 3 {
            award("Streak Starter")
        }

        return new
    }

    /// Applies new badges to a profile (call after `newBadges`).
    static func applyBadges(_ badges: [String], to profile: UserProfile) {
        for badge in badges where !profile.badges.contains(badge) {
            profile.badges.append(badge)
        }
    }
}
