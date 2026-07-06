import Testing
@testable import BreathRelaxStretch

struct TodayViewTests {

    @Test func morningHoursAreWakeUp() {
        for hour in [5, 7, 10] {
            #expect(TodayView.timeOfDayFocus(forHour: hour) == .wakeUp)
        }
    }

    @Test func eveningAndOvernightHoursAreUnwind() {
        for hour in [20, 22, 23, 0, 2, 4] {
            #expect(TodayView.timeOfDayFocus(forHour: hour) == .unwind)
        }
    }

    @Test func middayHoursHaveNoTimeOfDayOverride() {
        for hour in [11, 14, 19] {
            #expect(TodayView.timeOfDayFocus(forHour: hour) == .none)
        }
    }

    @Test func heroTitlesMatchFocus() {
        #expect(TodayView.TimeOfDayFocus.wakeUp.heroTitle == "Wake Up")
        #expect(TodayView.TimeOfDayFocus.unwind.heroTitle == "Unwind")
        #expect(TodayView.TimeOfDayFocus.none.heroTitle == "Today's session")
    }
}
