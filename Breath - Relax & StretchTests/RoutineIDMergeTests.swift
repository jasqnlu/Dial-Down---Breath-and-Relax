import Foundation
import Testing
@testable import BreathRelaxStretch

@Suite struct RoutineIDMergeTests {
    @Test func appendsNewIDsToBase() {
        let boxBreathing = UUID()
        let neckRoll = UUID()

        let merged = RoutineIDMerge.appending([neckRoll], to: [boxBreathing])

        #expect(merged == [boxBreathing, neckRoll])
    }

    @Test func skipsDuplicatesAlreadyInBase() {
        let boxBreathing = UUID()

        let merged = RoutineIDMerge.appending([boxBreathing], to: [boxBreathing])

        #expect(merged == [boxBreathing])
    }

    @Test func preservesBaseOrderThenAppendsInPickedOrder() {
        let boxBreathing = UUID()
        let catCow = UUID()
        let neckRoll = UUID()
        let shoulderShrug = UUID()

        let merged = RoutineIDMerge.appending([shoulderShrug, neckRoll], to: [boxBreathing, catCow])

        #expect(merged == [boxBreathing, catCow, shoulderShrug, neckRoll])
    }
}
