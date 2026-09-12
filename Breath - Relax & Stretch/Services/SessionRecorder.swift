import Foundation
import SwiftData
import os

/// Everything a completed session (stretch routine or breathing pattern) needs
/// recorded: the SwiftData `Session` row, `UserProfile` stats/streak/badges,
/// HealthKit, and Calendar. `SessionPlayerView` and
/// `BreathingView` each drove this pipeline independently and had already
/// drifted once (breathing passed no `bodyPartsCovered`) — this is the single
/// place it happens now.
@MainActor
enum SessionRecorder {

    enum HealthKitKind {
        case stretch
        case breathing
    }

    struct Input {
        var routineID: UUID
        var startedAt: Date
        var completedAt: Date
        var completionPercent: Double
        var pointsEarned: Int
        var exerciseIDs: [UUID] = []
        var sessionLabel: String? = nil
        var roundsCompleted: Int = 0
        var bodyPartsCovered: Set<String> = []
        var isBorrowedRoutine: Bool = false
        var calendarTitle: String
        var healthKitKind: HealthKitKind
    }

    /// The streak state after a `record()` call — split out from a bare Int
    /// so callers (the post-session summary screen) can tell a genuine
    /// streak bump from a second session completed the same day, which
    /// leaves `streak` unchanged and shouldn't replay the "streak up" beat.
    struct Outcome {
        var streak: Int
        var streakIncreased: Bool
    }

    /// Persists the session, updates profile stats/streak/badges, and fans out
    /// to HealthKit/Calendar. Returns the profile's streak state after
    /// the update (zero/unchanged if no profile exists yet) so callers can
    /// use it without a second fetch.
    @discardableResult
    static func record(
        _ input: Input,
        modelContext: ModelContext,
        calendarSyncEnabled: Bool
    ) -> Outcome {
        let session = Session(
            routineID: input.routineID,
            startedAt: input.startedAt,
            completionPercent: input.completionPercent,
            pointsEarned: input.pointsEarned
        )
        session.completedAt = input.completedAt
        session.exerciseIDs = input.exerciseIDs
        session.sessionLabel = input.sessionLabel
        session.roundsCompleted = input.roundsCompleted
        modelContext.insert(session)

        var outcome = Outcome(streak: 0, streakIncreased: false)
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.totalPoints += input.pointsEarned
            profile.totalMinutes += max(1, Int(input.completedAt.timeIntervalSince(input.startedAt) / 60))
            let previousStreak = profile.streak
            GamificationService.updateStreak(for: profile)
            let newBadges = GamificationService.newBadges(for: profile, bodyPartsCovered: input.bodyPartsCovered)
            GamificationService.applyBadges(newBadges, to: profile)
            if input.isBorrowedRoutine {
                GamificationService.awardBadge("Borrowed & Built", to: profile)
            }
            outcome = Outcome(streak: profile.streak, streakIncreased: profile.streak > previousStreak)
        }

        do {
            try modelContext.save()
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "sessionRecorder").warning("Save failed: \(error)")
        }

        // HealthKit — no-op unless the user connected Apple Health in Settings;
        // never prompts here.
        Task {
            switch input.healthKitKind {
            case .stretch:
                await HealthKitService.shared.logStretchSession(startedAt: input.startedAt, completedAt: input.completedAt)
            case .breathing:
                await HealthKitService.shared.logBreathingSession(startedAt: input.startedAt, completedAt: input.completedAt)
            }
        }

        // Calendar — opt-in, mirrors the session as an event
        if calendarSyncEnabled {
            CalendarService.shared.logCompletedSession(
                title: input.calendarTitle, start: input.startedAt, end: input.completedAt)
        }

        return outcome
    }
}
