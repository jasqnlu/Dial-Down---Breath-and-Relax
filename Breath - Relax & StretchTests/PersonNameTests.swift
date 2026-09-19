import Testing
@testable import BreathRelaxStretch

@MainActor
struct PersonNameTests {

    @Test func initTrimsWhitespace() {
        let name = PersonName(first: "  Ada ", last: "\nLovelace  ")
        #expect(name.first == "Ada")
        #expect(name.last == "Lovelace")
    }

    @Test func initClampsEachPartToTheMaxLength() {
        let long = String(repeating: "a", count: 60)
        let name = PersonName(first: long, last: long)
        #expect(name.first.count == PersonName.maxComponentLength)
        #expect(name.last.count == PersonName.maxComponentLength)
    }

    @Test func isCompleteNeedsBothParts() {
        #expect(PersonName(first: "Ada", last: "Lovelace").isComplete)
        #expect(!PersonName(first: "Ada", last: "").isComplete)
        #expect(!PersonName(first: "", last: "Lovelace").isComplete)
        #expect(!PersonName(first: "  ", last: "  ").isComplete)
    }

    @Test func fullNameJoinsNonEmptyPartsWithASpace() {
        #expect(PersonName(first: "Ada", last: "Lovelace").fullName == "Ada Lovelace")
        #expect(PersonName(first: "Ada", last: "").fullName == "Ada")
        #expect(PersonName.empty.fullName == "")
    }

    @Test func splitTakesTheFirstWordAsFirstAndTheRestAsLast() {
        #expect(PersonName.split(fullName: "Ada Lovelace") == PersonName(first: "Ada", last: "Lovelace"))
        #expect(PersonName.split(fullName: "Ada Byron King") == PersonName(first: "Ada", last: "Byron King"))
        #expect(PersonName.split(fullName: "Ada") == PersonName(first: "Ada", last: ""))
    }

    @Test func splitIgnoresPlaceholderNames() {
        #expect(PersonName.split(fullName: "") == .empty)
        #expect(PersonName.split(fullName: "Apple User") == .empty)
        #expect(PersonName.split(fullName: "guest") == .empty)
        #expect(PersonName.split(fullName: "User") == .empty)
    }
}
