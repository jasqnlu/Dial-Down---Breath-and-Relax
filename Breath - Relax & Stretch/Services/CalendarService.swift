import EventKit

// MARK: - CalendarService
// Optional EventKit integration: logs completed sessions as calendar events
// and suggests a free slot today for the next session.

final class CalendarService {
    static let shared = CalendarService()
    let store = EKEventStore()
    private init() {}

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    /// Logs a completed session as a same-time calendar event so it shows up
    /// alongside the rest of the user's day.
    func logCompletedSession(title: String, start: Date, end: Date) {
        guard isAuthorized else { return }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = max(end, start.addingTimeInterval(60))
        event.calendar = store.defaultCalendarForNewEvents
        event.notes = "Logged by Dial Down"
        try? store.save(event, span: .thisEvent)
    }

    /// Finds the next free slot of at least `minutes` between now and 9pm today.
    func suggestFreeSlot(minutes: Int = 15) -> Date? {
        guard isAuthorized else { return nil }
        let cal = Calendar.current
        let now = Date()
        guard
            let windowEnd = cal.date(bySettingHour: 21, minute: 0, second: 0, of: now),
            now < windowEnd
        else { return nil }

        let predicate = store.predicateForEvents(withStart: now, end: windowEnd, calendars: nil)
        let busyEvents = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        var cursor = now
        let slotLength = TimeInterval(minutes * 60)
        for event in busyEvents {
            if event.startDate.timeIntervalSince(cursor) >= slotLength {
                return cursor
            }
            if event.endDate > cursor {
                cursor = event.endDate
            }
        }
        return windowEnd.timeIntervalSince(cursor) >= slotLength ? cursor : nil
    }
}
