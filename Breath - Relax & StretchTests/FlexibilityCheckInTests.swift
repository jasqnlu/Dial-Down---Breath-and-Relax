import Testing
import Foundation
import SwiftData
@testable import BreathRelaxStretch

@MainActor
struct FlexibilityCheckInTests {

    private func checkIn(_ test: FlexibilityTest, level: Int, daysAgo: Double) -> FlexibilityCheckIn {
        FlexibilityCheckIn(date: Date(timeIntervalSinceNow: -daysAgo * 86_400), test: test, level: level)
    }

    // MARK: - Catalog invariants

    @Test func catalogHasFourTestsWithFiveLevelsEach() {
        #expect(FlexibilityTest.allCases.count == 4)
        for test in FlexibilityTest.allCases {
            #expect(test.levels.count == 5, "\(test.name) must have 5 ordinal levels")
            #expect(!test.instructions.isEmpty, "\(test.name) needs instructions")
            #expect(!test.name.isEmpty)
            #expect(!test.targetArea.isEmpty)
            #expect(!test.icon.isEmpty)
        }
    }

    @Test func catalogIDsAreUnique() {
        let ids = FlexibilityTest.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Model

    @Test func initClampsLevelIntoRange() {
        #expect(FlexibilityCheckIn(test: .toeTouch, level: 99).level == 4)
        #expect(FlexibilityCheckIn(test: .toeTouch, level: -3).level == 0)
        #expect(FlexibilityCheckIn(test: .toeTouch, level: 2).level == 2)
    }

    @Test func testAccessorRoundTripsAndSurvivesUnknownRawValue() {
        let checkIn = FlexibilityCheckIn(test: .butterfly, level: 1)
        #expect(checkIn.test == .butterfly)

        checkIn.testID = "test-removed-in-a-future-version"
        #expect(checkIn.test == nil) // must degrade, not crash
    }

    @Test func modelRoundTripsThroughSwiftData() throws {
        let container = try ModelContainer(
            for: FlexibilityCheckIn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.insert(FlexibilityCheckIn(test: .neckRotation, level: 3))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FlexibilityCheckIn>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.test == .neckRotation)
        #expect(fetched.first?.level == 3)
    }

    // MARK: - FlexibilityStats.latest / delta

    @Test func latestPicksTheMostRecentForTheRightTest() {
        let checkIns = [
            checkIn(.toeTouch, level: 1, daysAgo: 30),
            checkIn(.toeTouch, level: 3, daysAgo: 1),
            checkIn(.butterfly, level: 4, daysAgo: 0)
        ]
        #expect(FlexibilityStats.latest(checkIns, for: .toeTouch)?.level == 3)
        #expect(FlexibilityStats.latest(checkIns, for: .neckRotation) == nil)
    }

    @Test func deltaIsLatestMinusFirst() {
        let checkIns = [
            checkIn(.toeTouch, level: 1, daysAgo: 30),
            checkIn(.toeTouch, level: 0, daysAgo: 15), // a dip along the way doesn't matter
            checkIn(.toeTouch, level: 3, daysAgo: 1)
        ]
        #expect(FlexibilityStats.delta(checkIns, for: .toeTouch) == 2)
    }

    @Test func deltaCanBeNegative() {
        let checkIns = [
            checkIn(.shoulderReach, level: 4, daysAgo: 20),
            checkIn(.shoulderReach, level: 2, daysAgo: 2)
        ]
        #expect(FlexibilityStats.delta(checkIns, for: .shoulderReach) == -2)
    }

    @Test func deltaNeedsAtLeastTwoCheckIns() {
        let checkIns = [checkIn(.toeTouch, level: 2, daysAgo: 5)]
        #expect(FlexibilityStats.delta(checkIns, for: .toeTouch) == nil)
        #expect(FlexibilityStats.delta([], for: .toeTouch) == nil)
    }

    // MARK: - FlexibilityStats.isDue (14-day cadence)

    @Test func isDueWithNoHistory() {
        #expect(FlexibilityStats.isDue([]))
    }

    @Test func isNotDueRightAfterACheckIn() {
        #expect(!FlexibilityStats.isDue([checkIn(.toeTouch, level: 2, daysAgo: 1)]))
    }

    @Test func isDueAfterFourteenDays() {
        #expect(FlexibilityStats.isDue([checkIn(.toeTouch, level: 2, daysAgo: 15)]))
    }

    @Test func anyRecentTestResetsTheCadence() {
        let checkIns = [
            checkIn(.toeTouch, level: 2, daysAgo: 40),
            checkIn(.butterfly, level: 1, daysAgo: 3)
        ]
        #expect(!FlexibilityStats.isDue(checkIns))
    }
}
