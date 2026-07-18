import Testing
import simd
@testable import BreathRelaxStretch

struct HeadZonesTests {
    @Test func returnsFourCandidatesIncludingForehead() {
        let c = HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08))
        #expect(c.count == 4)
        #expect(c.contains { $0.name == "Forehead" })
    }

    @Test func infersLeftSideForPositiveX() {
        let names = Set(HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)).map(\.name))
        #expect(names == ["Forehead", "Left Eye", "Left Temple", "Left Jaw"])
    }

    @Test func infersRightSideForNegativeX() {
        let names = Set(HeadZones.candidates(forTapAt: SIMD3(-0.05, 0.85, 0.08)).map(\.name))
        #expect(names == ["Forehead", "Right Eye", "Right Temple", "Right Jaw"])
    }

    @Test func bilateralAnchorsMirrorAcrossX() {
        let l = HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)).first { $0.name == "Left Eye" }!
        let r = HeadZones.candidates(forTapAt: SIMD3(-0.05, 0.85, 0.08)).first { $0.name == "Right Eye" }!
        #expect(l.point.x == -r.point.x)
        #expect(l.point.y == r.point.y)
    }

    @Test func foreheadIsMidline() {
        let f = HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)).first { $0.name == "Forehead" }!
        #expect(f.point.x == 0)
    }

    @Test func candidatesHaveNoBoxBounds() {
        for c in HeadZones.candidates(forTapAt: SIMD3(0.05, 0.85, 0.08)) {
            #expect(c.minBound == .zero && c.maxBound == .zero)
        }
    }
}
