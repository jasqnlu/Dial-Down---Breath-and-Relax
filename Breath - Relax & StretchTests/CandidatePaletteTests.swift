import Testing
import SwiftUI
@testable import BreathRelaxStretch

@Suite("Body map candidate palette")
struct CandidatePaletteTests {
    @Test("palette has no cyan entry")
    func noCyanEntry() {
        // The old index-1 entry was Color(red: 0.17, green: 0.71, blue: 0.79)
        // — cyan (blue and green both far exceed red). Every entry should
        // now have red as its largest or a close, non-cyan-shaped component.
        for color in CandidatePalette.colors {
            let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
            let isCyanShaped = b > 0.6 && g > 0.6 && r < 0.3
            #expect(!isCyanShaped, "Found a cyan-shaped color in CandidatePalette: r=\(r) g=\(g) b=\(b)")
        }
    }

    @Test("palette still has four distinct colors")
    func fourDistinctColors() {
        #expect(CandidatePalette.colors.count == 4)
        #expect(Set(CandidatePalette.colors.map { $0.description }).count == 4)
    }
}
