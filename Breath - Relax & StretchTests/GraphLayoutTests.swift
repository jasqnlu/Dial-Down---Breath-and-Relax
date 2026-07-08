import Testing
import CoreGraphics
@testable import BreathRelaxStretch

struct GraphLayoutTests {
    @Test func categoryPositionsAreEvenlySpacedOnUnitRing() {
        let count = 8
        for index in 0..<count {
            let point = GraphLayout.categoryPosition(index: index, count: count)
            let distance = (point.x * point.x + point.y * point.y).squareRoot()
            #expect(abs(distance - 1) < 0.0001)
        }
    }

    @Test func firstCategorySitsAtTwelveOClock() {
        let point = GraphLayout.categoryPosition(index: 0, count: 8)
        #expect(abs(point.x) < 0.0001)
        #expect(abs(point.y - (-1)) < 0.0001)
    }

    @Test func categoryPositionsAreAllDistinct() {
        let count = 8
        let points = (0..<count).map { GraphLayout.categoryPosition(index: $0, count: count) }
        for i in 0..<points.count {
            for j in (i+1)..<points.count {
                let dx = points[i].x - points[j].x
                let dy = points[i].y - points[j].y
                #expect((dx*dx + dy*dy).squareRoot() > 0.01)
            }
        }
    }

    @Test func exercisePositionsSitAtGivenRadiusFromCenter() {
        let center = CGPoint(x: 0.3, y: -0.2)
        let radius: CGFloat = 0.25
        for index in 0..<5 {
            let point = GraphLayout.exercisePosition(index: index, count: 5, around: center, radius: radius)
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = (dx*dx + dy*dy).squareRoot()
            #expect(abs(distance - radius) < 0.0001)
        }
    }

    @Test func zeroCountReturnsCenterOrZeroWithoutCrashing() {
        #expect(GraphLayout.categoryPosition(index: 0, count: 0) == .zero)
        let center = CGPoint(x: 1, y: 1)
        #expect(GraphLayout.exercisePosition(index: 0, count: 0, around: center, radius: 0.3) == center)
    }

    @Test func ringPositionsReturnsExactlyCountPoints() {
        for count in [1, 7, 14, 40] {
            let positions = GraphLayout.ringPositions(count: count, around: .zero, baseRadius: 0.3, ringSpacing: 0.16)
            #expect(positions.count == count)
        }
    }

    @Test func ringPositionsFillsInnerRingBeforeOuter() {
        // With perRing 7, the 8th point (index 7) must be on ring 1 (radius
        // baseRadius + ringSpacing), not ring 0.
        let positions = GraphLayout.ringPositions(count: 8, around: .zero, baseRadius: 0.3, ringSpacing: 0.16, perRing: 7)
        let seventhDistance = (positions[6].x * positions[6].x + positions[6].y * positions[6].y).squareRoot()
        let eighthDistance = (positions[7].x * positions[7].x + positions[7].y * positions[7].y).squareRoot()
        #expect(abs(seventhDistance - 0.3) < 0.0001)
        #expect(abs(eighthDistance - 0.46) < 0.0001)
    }

    @Test func ringPositionsZeroCountReturnsEmpty() {
        #expect(GraphLayout.ringPositions(count: 0, around: .zero, baseRadius: 0.3, ringSpacing: 0.16).isEmpty)
    }
}
