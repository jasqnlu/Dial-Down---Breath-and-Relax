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

    /// Amber (new) has red > blue; the old teal/mint-cyan had blue >= red.
    /// This is a real regression test, not just an existence check — it
    /// would fail if `luminaPrimary`'s dark value were ever reverted to
    /// its old cyan hex (0x6ED8C5: R=110, G=216, B=197).
    @Test("primary dark value is warm (red > blue), not cyan")
    func primaryDarkIsWarm() {
        let resolved = UIColor(Color.luminaPrimary)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r > b)
    }

    @Test("gradient start dark value is warm (red > blue), not cyan")
    func gradientStartDarkIsWarm() {
        let resolved = UIColor(Color.luminaGradientStart)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r > b)
    }

    /// Xcode's asset-catalog AccentColor is a separate color source from the
    /// `luminaPrimary` Swift token. During final verification, it was found
    /// still cyan/teal in dark mode despite LuminaTheme.swift being updated.
    /// This test ensures the AccentColor asset was also updated to warm amber.
    /// Uses Color("AccentColor") to directly resolve the named asset from the
    /// catalog, bypassing environment-level global-tint wiring.
    @Test("asset-catalog AccentColor dark value is warm (red > blue), not cyan")
    func accentColorAssetDarkIsWarm() {
        let resolved = UIColor(Color("AccentColor"))
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(r > b)
    }
}
