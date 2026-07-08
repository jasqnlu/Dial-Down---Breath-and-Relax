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
}
