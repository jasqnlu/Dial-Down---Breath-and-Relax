import Testing
import UIKit
@testable import BreathRelaxStretch

@Suite("Lumina font registration")
struct LuminaFontsTests {
    @Test("all five Manrope weights load after registration")
    func manropeLoads() {
        LuminaFonts.registerAll()
        let names = ["ManropeExtraLight-Regular", "ManropeExtraLight-Medium", "ManropeExtraLight-SemiBold",
                     "ManropeExtraLight-Bold", "ManropeExtraLight-ExtraBold"]
        for name in names {
            #expect(UIFont(name: name, size: 14) != nil, "\(name) failed to load")
        }
    }
}
