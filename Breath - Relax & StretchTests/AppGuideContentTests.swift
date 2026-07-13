import Foundation
import Testing
@testable import BreathRelaxStretch

struct AppGuideContentTests {
    @Test func guideCoversAllMainTabsInOrder() {
        #expect(AppGuideContent.pages.map(\.title) == [
            "Today",
            "Body Map",
            "Exercises",
            "Breathe",
            "Routines",
            "Profile"
        ])
    }

    @Test func breatheGuideTellsUsersToTapTheCircle() {
        let breathePage = AppGuideContent.pages.first { $0.title == "Breathe" }

        #expect(breathePage?.description.localizedCaseInsensitiveContains("tap the circle") == true)
    }
}
