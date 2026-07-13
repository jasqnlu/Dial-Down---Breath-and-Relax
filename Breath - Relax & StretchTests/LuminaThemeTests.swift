import Testing
import SwiftUI
import UIKit
@testable import BreathRelaxStretch

@Suite("Lumina theme colors")
struct LuminaThemeTests {
    @Test("primary resolves differently in light and dark")
    func primaryIsDynamic() {
        let ui = UIColor(Color.luminaPrimary)
        let light = ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light != dark)
    }

    @Test("surface resolves differently in light and dark")
    func surfaceIsDynamic() {
        let ui = UIColor(Color.luminaSurface)
        #expect(ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
             != ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
    }
}
