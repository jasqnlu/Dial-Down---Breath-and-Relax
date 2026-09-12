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
        isBorrowedRoutine: Bool = false
    ) -> SessionRecorder.Input {
        SessionRecorder.Input(
            routineID: routineID,
            startedAt: Date().addingTimeInterval(-120),
            completedAt: Date(),
            completionPercent: 1.0,
            pointsEarned: pointsEarned,
            exerciseIDs: [UUID()],
            bodyPartsCovered: bodyPartsCovered,
            isBorrowedRoutine: isBorrowedRoutine,
            calendarTitle: "Test Session",
            healthKitKind: .stretch
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
