import UIKit
import os

/// The app is pure-SwiftUI-lifecycle everywhere else; this exists solely to
/// receive the two UIApplicationDelegate callbacks SwiftUI's App protocol
/// doesn't expose: the APNs device token (or the failure to get one).
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            guard SupabaseService.isConfigured, AuthManager.shared.isBackendAuthenticated else { return }
            try? await SupabaseService.shared.registerPushToken(
                deviceToken: hex,
                timezone: TimeZone.current.identifier
            )
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Best-effort feature — matches every other Supabase call site in
        // this app: log and move on, nothing user-facing.
        Logger(subsystem: "com.jasonlu.breath", category: "push").warning("APNs registration failed: \(error)")
    }
}

/// Shared eligibility check — the app only ever calls
/// `UIApplication.shared.registerForRemoteNotifications()` when both of
/// these hold. Called from three places: app launch (below), the
/// Reminders toggle (ProfileSettingsTab), and first-run opt-in
/// (NotificationsPage) — kept as one function so the rule can't drift
/// between them.
@MainActor
func shouldRegisterForRemotePush() -> Bool {
    UserDefaults.standard.bool(forKey: "notificationsEnabled")
        && AuthManager.shared.isBackendAuthenticated
}
