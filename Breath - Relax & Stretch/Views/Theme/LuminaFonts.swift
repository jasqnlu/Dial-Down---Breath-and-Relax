import SwiftUI
import CoreText

// MARK: - Manrope registration
//
// The target generates its Info.plist (GENERATE_INFOPLIST_FILE), which has
// no UIAppFonts build setting, so fonts are registered at runtime instead.

enum LuminaFonts {
    private static var didRegister = false

    /// Idempotent. Called from the App initializer (and from unit tests).
    static func registerAll() {
        guard !didRegister else { return }
        didRegister = true

        let names = ["ManropeExtraLight-Regular", "ManropeExtraLight-Medium", "ManropeExtraLight-SemiBold",
                     "ManropeExtraLight-Bold", "ManropeExtraLight-ExtraBold"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Semantic type scale (Lumina Mobility)

extension Font {
    static let luminaDisplay     = Font.custom("ManropeExtraLight-ExtraBold", size: 34, relativeTo: .largeTitle)
    static let luminaHeadline    = Font.custom("ManropeExtraLight-ExtraBold", size: 26, relativeTo: .title)
    static let luminaTitle       = Font.custom("ManropeExtraLight-Bold",      size: 20, relativeTo: .title3)
    static let luminaCardTitle   = Font.custom("ManropeExtraLight-SemiBold",  size: 17, relativeTo: .headline)
    static let luminaBody        = Font.custom("ManropeExtraLight-Regular",   size: 16, relativeTo: .body)
    static let luminaSubheadline = Font.custom("ManropeExtraLight-Regular",   size: 15, relativeTo: .subheadline)
    static let luminaLabel       = Font.custom("ManropeExtraLight-SemiBold",  size: 13, relativeTo: .footnote)
    static let luminaCaption     = Font.custom("ManropeExtraLight-Medium",    size: 12, relativeTo: .caption)
}
