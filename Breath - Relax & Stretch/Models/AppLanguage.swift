import Foundation

/// The in-app language choice, persisted under `AppLanguage.storageKey`.
/// `.system` means "follow the device"; the others force that language via
/// the SwiftUI `\.locale` environment set at the app root.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case es
    case fr
    case zhHans = "zh-Hans"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// `nil` for `.system` so the environment keeps the device locale.
    var locale: Locale? {
        self == .system ? nil : Locale(identifier: rawValue)
    }

    /// Each language is labelled in itself, so a user who can't read the
    /// current UI language can still find theirs. `nil` for `.system`, whose
    /// label is a localized "System Default" supplied by the view.
    var nativeName: String? {
        switch self {
        case .system: nil
        case .en:     "English"
        case .es:     "Español"
        case .fr:     "Français"
        case .zhHans: "简体中文"
        }
    }

    /// Unknown or empty stored values fall back to `.system`.
    init(stored: String) {
        self = AppLanguage(rawValue: stored) ?? .system
    }

    /// The saved choice, for code outside the view tree (formatters, notification
    /// text, model strings) that can't read the SwiftUI `\.locale` environment.
    static func current(defaults: UserDefaults = .standard) -> AppLanguage {
        AppLanguage(stored: defaults.string(forKey: storageKey) ?? "")
    }

    /// BCP-47 tag for spoken voice cues; `nil` lets the system pick its default voice.
    var speechLanguage: String? {
        switch self {
        case .system: nil
        case .en:     "en-US"
        case .es:     "es-ES"
        case .fr:     "fr-FR"
        case .zhHans: "zh-CN"
        }
    }

    /// The concrete language in effect: itself, or — for `.system` — the shipped
    /// language the device prefers (English when none matches).
    var resolved: AppLanguage {
        guard self == .system else { return self }
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        return AppLanguage.allCases.first { $0 != .system && preferred.hasPrefix($0.rawValue) } ?? .en
    }

    /// Never nil: the explicit locale, or the device's for `.system`.
    var effectiveLocale: Locale { locale ?? .autoupdatingCurrent }
}

/// Resolves a catalog key to a `String` for the chosen language — for the places
/// SwiftUI's own `Text("literal")` lookup can't reach (plain `String` values,
/// notification bodies, `DateFormatter` output). Views should still prefer
/// literals / `LocalizedStringKey`.
enum L10n {
    static func string(_ key: String, language: AppLanguage = .current()) -> String {
        guard language != .system,
              let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return NSLocalizedString(key, comment: "") }
        // `value: key` makes a missing entry fall back to the key (English source).
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
