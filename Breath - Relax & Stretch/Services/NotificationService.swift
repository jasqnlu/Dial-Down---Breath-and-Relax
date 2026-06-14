import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()
    private init() {}

    // MARK: - Permission

    /// Requests UNUserNotificationCenter authorization for alerts, sounds, and badges.
    /// Returns `true` if permission was granted (either now or previously).
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule

    /// Schedules a repeating daily reminder at the given hour.
    /// Any previously scheduled reminder with the same identifier is replaced.
    ///
    /// - Parameters:
    ///   - hour: Hour of day (0-23) at which to fire the notification.
    ///   - daysPerWeek: Reserved for future use (e.g., per-weekday scheduling).
    ///                  Currently the notification repeats every day regardless of this value.
    func scheduleDailyReminder(hour: Int, daysPerWeek: Int) {
        let center = UNUserNotificationCenter.current()

        // Remove any existing reminder first so we don't stack duplicates.
        center.removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.dailyReminder])

        let content = UNMutableNotificationContent()
        content.title = "Time to Breathe & Stretch 🧘"
        content.body  = "Your daily wellness session is waiting. Just 5 minutes makes a difference."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour   = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.dailyReminder,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] Failed to schedule reminder: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cancel

    /// Removes all pending reminders scheduled by this service.
    func cancelReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [NotificationIdentifier.dailyReminder])
    }

    // MARK: - Status

    /// Returns the current UNAuthorizationStatus without prompting the user.
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}

// MARK: - Notification Identifiers

private enum NotificationIdentifier {
    static let dailyReminder = "daily-reminder"
}
