import Testing
@testable import BreathRelaxStretch

@Suite("Body trivia")
struct BodyTriviaTests {
    @Test("has a curated, non-empty fact list with no duplicates")
    func factListIsCuratedAndUnique() {
        #expect(BodyTrivia.facts.count >= 10)
        #expect(Set(BodyTrivia.facts).count == BodyTrivia.facts.count)
    }

    @Test("randomFact always returns a fact from the curated list")
    func randomFactComesFromCuratedList() {
        for _ in 0..<20 {
            #expect(BodyTrivia.facts.contains(BodyTrivia.randomFact()))
        }
    }

    @Test("randomFact never repeats the excluded fact")
    func randomFactNeverRepeatsExcluded() {
        let current = BodyTrivia.facts[0]
        for _ in 0..<50 {
            #expect(BodyTrivia.randomFact(excluding: current) != current)
        }
    }
}
