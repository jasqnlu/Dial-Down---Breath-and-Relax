import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct PoseGlyphIconRenderingTests {
    @Test func everyArchetypeRendersAnImage() {
        for id in PoseArchetypeID.allCases {
            let archetype = PoseArchetypeLibrary.all[id]!
            let icon = PoseGlyphIcon(archetype: archetype, mirrored: false, color: .teal, size: 96)
            let renderer = ImageRenderer(content: icon)
            #expect(renderer.cgImage != nil, "\(id) failed to render to an image")
        }
    }

    @Test func mirroredVariantAlsoRenders() {
        let archetype = PoseArchetypeLibrary.all[.seatedTwist]!
        let icon = PoseGlyphIcon(archetype: archetype, mirrored: true, color: .indigo, size: 96)
        let renderer = ImageRenderer(content: icon)
        #expect(renderer.cgImage != nil)
    }
    @Test func circularAccentRendersAtProductionSizes() {
        let archetype = PoseArchetypeLibrary.all[.standingNeutral]!
        for size in [48, 60, 72, 96] {
            let icon = PoseGlyphIcon(archetype: archetype, mirrored: false,
                                     color: .orange, size: CGFloat(size), motion: .circular)
            #expect(ImageRenderer(content: icon).cgImage != nil, "Failed at \(size)pt")
        }
    }
}
