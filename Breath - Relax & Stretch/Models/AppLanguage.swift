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
}
