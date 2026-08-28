import Testing
import SwiftUI
@testable import BreathRelaxStretch

@MainActor
struct CategoryTouchGlyphRenderingTests {
    @Test func everyCategoryRendersAnImage() {
        for category in ExerciseCategory.allCases {
            let renderer = ImageRenderer(content: CategoryTouchGlyph(category: category, size: 84))
            #expect(renderer.cgImage != nil, "\(category) failed to render")
        }
    }
}
