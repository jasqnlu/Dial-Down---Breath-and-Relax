import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()
    private init() {}

    // MARK: - Permission

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

    /// Schedules daily reminders at `hour` on each day in `weekdays`.
    /// `weekdays` uses Calendar weekday numbers: 1 = Sunday … 7 = Saturday.
    /// Any previously scheduled reminders are replaced.
    func scheduleReminders(hour: Int, weekdays: Set<Int>) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        let content = UNMutableNotificationContent()
        content.title = L10n.string("Time to Breathe & Stretch")
        content.body  = L10n.string("Your daily wellness session is waiting. Just 5 minutes makes a difference.")
        content.sound = .default

        for weekday in weekdays {
            var components = DateComponents()
            components.weekday = weekday
            components.hour    = hour
            components.minute  = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifier(for: weekday),
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error {
                    print("[NotificationService] Failed to schedule weekday \(weekday): \(error)")
                }
            }
        }
    }

    // MARK: - Cancel

    func cancelReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: allIdentifiers)
    }

    // MARK: - Status

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Identifiers

    private var allIdentifiers: [String] {
        (1...7).map { identifier(for: $0) }
    }

    private func identifier(for weekday: Int) -> String {
        "reminder-weekday-\(weekday)"
    }
}
