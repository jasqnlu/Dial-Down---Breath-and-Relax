import Testing
import SwiftData
import Foundation
@testable import BreathRelaxStretch

// Covers the persistence/rewards pipeline SessionPlayerView and BreathingView
// both delegate to. calendarSyncEnabled is always passed false here so tests
// don't touch EventKit; HealthKit calls are safe no-ops in the test runner
// (unauthorized), same as they are in SwiftUI previews.
@MainActor
struct SessionRecorderTests {

    private func makeContext() -> ModelContext {
        let container = try! ModelContainer(
            for: Session.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func baseInput(
        routineID: UUID = UUID(),
        pointsEarned: Int = 20,
        bodyPartsCovered: Set<String> = [],
        difficultiesCovered: Set<Int> = [],
        isBorrowedRoutine: Bool = false,
        elapsedSeconds: TimeInterval = 120,
        startedAt: Date? = nil,
        healthKitKind: SessionRecorder.HealthKitKind = .stretch
    ) -> SessionRecorder.Input {
        let resolvedStartedAt = startedAt ?? Date().addingTimeInterval(-elapsedSeconds)
        return SessionRecorder.Input(
            routineID: routineID,
            startedAt: resolvedStartedAt,
            completedAt: startedAt != nil ? resolvedStartedAt.addingTimeInterval(elapsedSeconds) : Date(),
            completionPercent: 1.0,
            pointsEarned: pointsEarned,
            exerciseIDs: [UUID()],
            bodyPartsCovered: bodyPartsCovered,
            difficultiesCovered: difficultiesCovered,
            isBorrowedRoutine: isBorrowedRoutine,
            calendarTitle: "Test Session",
            healthKitKind: healthKitKind
        )
    }

    @Test func recordInsertsASessionWithTheGivenFields() {
        let context = makeContext()
        let routineID = UUID()
        let input = baseInput(routineID: routineID, pointsEarned: 15)

        SessionRecorder.record(input, modelContext: context, calendarSyncEnabled: false)

        let sessions = try! context.fetch(FetchDescriptor<Session>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.routineID == routineID)
        #expect(sessions.first?.pointsEarned == 15)
        #expect(sessions.first?.completionPercent == 1.0)
        #expect(sessions.first?.completedAt != nil)
    }

    @Test func recordUpdatesExistingProfileStatsAndStreak() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        let outcome = SessionRecorder.record(
            baseInput(pointsEarned: 20), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.totalPoints == 20)
        #expect(profile.totalMinutes >= 1)
        #expect(profile.streak == 1)
        #expect(profile.badges.contains("First Breath"))
        #expect(outcome.streak == 1)
        #expect(outcome.streakIncreased == true)
    }

    @Test func recordReportsNoStreakIncreaseOnASecondSessionTheSameDay() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(), modelContext: context,
            calendarSyncEnabled: false)
        let outcome = SessionRecorder.record(
            baseInput(), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.streak == 1)
        #expect(outcome.streak == 1)
        #expect(outcome.streakIncreased == false)
    }

    @Test func recordAwardsBorrowedBadgeForBorrowedRoutines() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(isBorrowedRoutine: true), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.badges.contains("Borrowed & Built"))
    }

    @Test func recordPassesBodyPartsCoveredThroughToBadgeEvaluation() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        let groups: Set<String> = ["Neck", "Shoulders", "Chest", "Back", "Core"]
        SessionRecorder.record(
            baseInput(bodyPartsCovered: groups), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.badges.contains("Full Body"))
    }

    @Test func recordWithoutAnExistingProfileStillInsertsTheSessionAndReturnsZeroStreak() {
        let context = makeContext()
        let outcome = SessionRecorder.record(
            baseInput(), modelContext: context,
            calendarSyncEnabled: false)

        #expect(outcome.streak == 0)
        #expect(outcome.streakIncreased == false)
        #expect(try! context.fetch(FetchDescriptor<Session>()).count == 1)
    }

    @Test func recordAwardsNoMinutesForASkipThroughUnderThirtySeconds() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(elapsedSeconds: 8), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.totalMinutes == 0)
    }

    @Test func recordAwardsOneMinuteForASessionAtLeastThirtySecondsLong() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(elapsedSeconds: 45), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.totalMinutes == 1)
    }

    @Test func recordRoundsMinutesToNearestForLongerSessions() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(elapsedSeconds: 340), modelContext: context,
            calendarSyncEnabled: false)

        #expect(profile.totalMinutes == 6)
    }

    @Test func recordTracksEarlyBirdSessionsByStartHour() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)
        let sevenAM = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!

        SessionRecorder.record(
            baseInput(startedAt: sevenAM), modelContext: context, calendarSyncEnabled: false)

        #expect(profile.earlyBirdSessionCount == 1)
        #expect(profile.nightOwlSessionCount == 0)
    }

    @Test func recordTracksNightOwlSessionsByStartHour() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)
        let elevenPM = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!

        SessionRecorder.record(
            baseInput(startedAt: elevenPM), modelContext: context, calendarSyncEnabled: false)

        #expect(profile.nightOwlSessionCount == 1)
        #expect(profile.earlyBirdSessionCount == 0)
    }

    @Test func recordTracksWeekendSessions() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)
        let calendar = Calendar.current
        // Find the next Saturday from today so this test is stable regardless of when it runs.
        var saturday = Date()
        while calendar.component(.weekday, from: saturday) != 7 {
            saturday = calendar.date(byAdding: .day, value: 1, to: saturday)!
        }

        SessionRecorder.record(
            baseInput(startedAt: saturday), modelContext: context, calendarSyncEnabled: false)

        #expect(profile.weekendSessionCount == 1)
    }

    @Test func recordAccumulatesCategoriesTouchedWithoutDuplicates() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(bodyPartsCovered: ["Neck", "Shoulders"]), modelContext: context, calendarSyncEnabled: false)
        SessionRecorder.record(
            baseInput(bodyPartsCovered: ["Neck", "Chest"]), modelContext: context, calendarSyncEnabled: false)

        #expect(Set(profile.categoriesTouched) == ["Neck", "Shoulders", "Chest"])
    }

    @Test func recordAccumulatesDifficultiesTouchedWithoutDuplicates() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(difficultiesCovered: [1, 2]), modelContext: context, calendarSyncEnabled: false)
        SessionRecorder.record(
            baseInput(difficultiesCovered: [2, 3]), modelContext: context, calendarSyncEnabled: false)

        #expect(Set(profile.difficultiesTouched) == [1, 2, 3])
    }

    @Test func recordSetsHasCompletedFlagsFromHealthKitKind() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        SessionRecorder.record(
            baseInput(healthKitKind: .breathing), modelContext: context, calendarSyncEnabled: false)

        #expect(profile.hasCompletedBreathing == true)
        #expect(profile.hasCompletedStretch == false)

        SessionRecorder.record(
            baseInput(healthKitKind: .stretch), modelContext: context, calendarSyncEnabled: false)

        #expect(profile.hasCompletedStretch == true)
    }

    @Test func recordOutcomeReportsNewlyEarnedBadges() {
        let context = makeContext()
        let profile = UserProfile(profileID: "test", displayName: "Tester")
        context.insert(profile)

        let outcome = SessionRecorder.record(
            baseInput(), modelContext: context, calendarSyncEnabled: false)

        #expect(outcome.newlyEarnedBadges == ["First Breath"])
    }

    @Test func recordCarriesBreathingSpecificFieldsThrough() {
        let context = makeContext()
        var input = baseInput()
        input.exerciseIDs = []
        input.sessionLabel = "Box"
        input.roundsCompleted = 5

        SessionRecorder.record(input, modelContext: context, calendarSyncEnabled: false)

        let session = try! context.fetch(FetchDescriptor<Session>()).first
        #expect(session?.sessionLabel == "Box")
        #expect(session?.roundsCompleted == 5)
        #expect(session?.exerciseIDs.isEmpty == true)
    }
}
