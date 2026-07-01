import Testing
import Foundation
@testable import BreathRelaxStretch

// Covers the point/streak/badge math in GamificationService. These are the
// rules that drive nearly every reward in the app, so the exact numbers below
// are the contract — if the formula changes, these should fail on purpose.
struct GamificationServiceTests {

    // MARK: - Fixtures

    private func makeExercise(duration: Int = 60, difficulty: Int = 1) -> Exercise {
        Exercise(name: "Test",
                 type: .stretch,
                 targetBodyParts: [],
                 durationSeconds: duration,
                 difficulty: difficulty,
                 instructions: [])
    }

    private func makeProfile(streak: Int = 0,
                             minutes: Int = 0,
                             points: Int = 0,
                             badges: [String] = [],
                             lastSession: Date? = nil) -> UserProfile {
        let p = UserProfile(profileID: "test", displayName: "Tester")
        p.streak = streak
        p.totalMinutes = minutes
        p.totalPoints = points
        p.badges = badges
        p.lastSessionDate = lastSession
        return p
    }

    // MARK: - Points

    @Test func pointsForNilExerciseIsZero() {
        #expect(GamificationService.points(for: nil, completion: 1.0) == 0)
    }

    @Test func pointsScaleWithDifficulty() {
        let e = makeExercise(duration: 60, difficulty: 1)
        // 1 min * 1.0 difficulty * 1.2 full-completion bonus * 10
        #expect(GamificationService.points(for: e, completion: 1.0) == 12)
        #expect(GamificationService.points(for: makeExercise(duration: 60, difficulty: 2), completion: 1.0) == 18)
        #expect(GamificationService.points(for: makeExercise(duration: 60, difficulty: 3), completion: 1.0) == 24)
    }

    @Test func pointsScaleWithDuration() {
        // 2 min * 1.0 * 1.2 * 10 = 24
        #expect(GamificationService.points(for: makeExercise(duration: 120, difficulty: 1), completion: 1.0) == 24)
    }

    @Test func completionBonusTiers() {
        let e = makeExercise(duration: 60, difficulty: 1)
        #expect(GamificationService.points(for: e, completion: 1.0)  == 12) // >= 1.0  -> x1.2
        #expect(GamificationService.points(for: e, completion: 0.75) == 10) // >= 0.75 -> x1.0 (boundary)
        #expect(GamificationService.points(for: e, completion: 0.74) == 7)  // <  0.75 -> x0.7
        #expect(GamificationService.points(for: e, completion: 0.0)  == 7)
    }

    @Test func unknownDifficultyFallsBackToBaseMultiplier() {
        // difficulty 5 isn't a known tier, so it uses the 1.0 default — same as difficulty 1.
        let base = GamificationService.points(for: makeExercise(duration: 60, difficulty: 1), completion: 1.0)
        #expect(GamificationService.points(for: makeExercise(duration: 60, difficulty: 5), completion: 1.0) == base)
    }

    @Test func pointsTruncateRatherThanRound() {
        // 1.5 min * 1.5 * 0.7 * 10 = 15.75 -> truncated to 15
        #expect(GamificationService.points(for: makeExercise(duration: 90, difficulty: 2), completion: 0.74) == 15)
    }

    @Test func pointsNeverDropBelowOne() {
        // A 1-second half-finished session rounds to 0 but is floored to 1.
        #expect(GamificationService.points(for: makeExercise(duration: 1, difficulty: 1), completion: 0.5) == 1)
    }

    // MARK: - Streak

    private func noon(daysAgo: Int) -> Date {
        let cal = Calendar.current
        let base = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        return cal.date(byAdding: .day, value: -daysAgo, to: base)!
    }

    @Test func firstEverSessionStartsStreakAtOne() {
        let p = makeProfile(lastSession: nil)
        GamificationService.updateStreak(for: p)
        #expect(p.streak == 1)
        #expect(Calendar.current.isDateInToday(p.lastSessionDate ?? .distantPast))
    }

    @Test func consecutiveDayIncrementsStreak() {
        let p = makeProfile(streak: 5, lastSession: noon(daysAgo: 1))
        GamificationService.updateStreak(for: p)
        #expect(p.streak == 6)
    }

    @Test func secondSessionSameDayLeavesStreakUnchanged() {
        let p = makeProfile(streak: 5, lastSession: noon(daysAgo: 0))
        GamificationService.updateStreak(for: p)
        #expect(p.streak == 5)
    }

    @Test func missedDayResetsStreakToOne() {
        let p = makeProfile(streak: 10, lastSession: noon(daysAgo: 3))
        GamificationService.updateStreak(for: p)
        #expect(p.streak == 1)
    }

    // MARK: - Badges (newBadges only reports, it does not mutate the profile)

    @Test func freshProfileEarnsOnlyFirstBreath() {
        #expect(GamificationService.newBadges(for: makeProfile()) == ["First Breath"])
    }

    @Test func newBadgesDoesNotMutateProfile() {
        let p = makeProfile(streak: 7)
        _ = GamificationService.newBadges(for: p)
        #expect(p.badges.isEmpty)
    }

    @Test func streakMilestonesUnlockInOrder() {
        #expect(GamificationService.newBadges(for: makeProfile(streak: 3)) == ["First Breath", "Streak Starter"])
        #expect(GamificationService.newBadges(for: makeProfile(streak: 7)) == ["First Breath", "Streak Starter", "Weekly Warrior"])
        #expect(GamificationService.newBadges(for: makeProfile(streak: 30)) ==
                ["First Breath", "Streak Starter", "Weekly Warrior", "Month of Mindfulness"])
    }

    @Test func alreadyEarnedBadgesAreNotReported() {
        // Streak qualifies for the first two, but the user already has them.
        let p = makeProfile(streak: 7, badges: ["First Breath", "Streak Starter"])
        #expect(GamificationService.newBadges(for: p) == ["Weekly Warrior"])
    }

    @Test func minuteAndPointMilestones() {
        #expect(GamificationService.newBadges(for: makeProfile(minutes: 60)) ==
                ["First Breath", "30 Min Club", "Hour Hero"])
        #expect(GamificationService.newBadges(for: makeProfile(points: 500)) ==
                ["First Breath", "Century", "High Achiever"])
    }

    @Test func fullBodyNeedsFiveDistinctMajorGroups() {
        let five: Set<String> = ["Neck", "Shoulders", "Chest", "Back", "Core"]
        #expect(GamificationService.newBadges(for: makeProfile(), bodyPartsCovered: five).contains("Full Body"))

        let four: Set<String> = ["Neck", "Shoulders", "Chest", "Back"]
        #expect(!GamificationService.newBadges(for: makeProfile(), bodyPartsCovered: four).contains("Full Body"))

        #expect(!GamificationService.newBadges(for: makeProfile(), bodyPartsCovered: []).contains("Full Body"))
    }

    @Test func fullBodyCountsGroupsNotIndividualParts() {
        // "Lower Back" and "Upper Back" both map to the single "Back" group, so
        // this set only covers 4 distinct groups and should not earn Full Body.
        let parts: Set<String> = ["Lower Back", "Upper Back", "Neck", "Core", "Hips"]
        #expect(!GamificationService.newBadges(for: makeProfile(), bodyPartsCovered: parts).contains("Full Body"))
    }

    @Test func everythingAtOnceReportsTheFullBadgeSet() {
        let p = makeProfile(streak: 30, minutes: 300, points: 1000)
        let groups: Set<String> = ["Neck", "Shoulders", "Chest", "Back", "Core"]
        #expect(GamificationService.newBadges(for: p, bodyPartsCovered: groups) == [
            "First Breath", "Streak Starter", "Weekly Warrior", "Month of Mindfulness",
            "30 Min Club", "Hour Hero", "5 Hour Club",
            "Century", "High Achiever", "Elite Breather",
            "Full Body"
        ])
    }

    // MARK: - awardBadge / applyBadges (these DO mutate the profile)

    @Test func awardBadgeAppendsOnlyOnce() {
        let p = makeProfile()
        #expect(GamificationService.awardBadge("Pioneer", to: p) == true)
        #expect(p.badges == ["Pioneer"])
        #expect(GamificationService.awardBadge("Pioneer", to: p) == false)
        #expect(p.badges == ["Pioneer"])
    }

    @Test func applyBadgesMergesWithoutDuplicates() {
        let p = makeProfile(badges: ["A"])
        GamificationService.applyBadges(["A", "B", "B", "C"], to: p)
        #expect(p.badges == ["A", "B", "C"])
    }
}
