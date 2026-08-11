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
}
