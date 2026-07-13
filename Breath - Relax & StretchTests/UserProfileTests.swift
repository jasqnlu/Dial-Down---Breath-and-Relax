import Testing
import SwiftData
import Foundation
@testable import BreathRelaxStretch

// Covers UserProfile.dedupe(in:), the defensive merge pass that folds
// duplicate profiles (possible if CloudKit sync produces two rows before a
// merge resolves) into a single survivor instead of leaving stats split
// non-deterministically across rows.
struct UserProfileTests {

    private func makeContext() -> ModelContext {
        let container = try! ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func dedupeNoOpsWithZeroOrOneProfile() {
        let context = makeContext()
        UserProfile.dedupe(in: context)

        let solo = UserProfile(profileID: "a", displayName: "Solo")
        context.insert(solo)
        try? context.save()
        UserProfile.dedupe(in: context)

        let all = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        #expect(all.count == 1)
    }

    @Test func dedupeMergesStatsIntoSurvivor() throws {
        let context = makeContext()

        let first = UserProfile(profileID: "a", displayName: "First")
        first.totalPoints = 100
        first.totalMinutes = 30
        first.streak = 3
        first.badges = ["First Breath"]

        let second = UserProfile(profileID: "a", displayName: "First")
        second.totalPoints = 50
        second.totalMinutes = 20
        second.streak = 7
        second.badges = ["Streak Starter"]

        context.insert(first)
        context.insert(second)
        try? context.save()

        UserProfile.dedupe(in: context)

        let all = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        #expect(all.count == 1)
        let survivor = try #require(all.first)
        #expect(survivor.totalPoints == 150)
        #expect(survivor.totalMinutes == 50)
        #expect(survivor.streak == 7)
        #expect(Set(survivor.badges) == ["First Breath", "Streak Starter"])
    }

    @Test func dedupeKeepsLatestLastSessionDate() {
        let context = makeContext()

        let older = UserProfile(profileID: "a", displayName: "A")
        older.lastSessionDate = Date(timeIntervalSince1970: 1000)

        let newer = UserProfile(profileID: "a", displayName: "A")
        newer.lastSessionDate = Date(timeIntervalSince1970: 2000)

        context.insert(older)
        context.insert(newer)
        try? context.save()

        UserProfile.dedupe(in: context)

        let all = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        #expect(all.first?.lastSessionDate == Date(timeIntervalSince1970: 2000))
    }
}
