import Foundation

struct AppGuidePage: Identifiable, Equatable {
    let icon: String
    let title: String
    let description: String

    var id: String { title }
}

enum AppGuideContent {
    static let pages: [AppGuidePage] = [
        AppGuidePage(
            icon: "sun.max",
            title: "Today",
            description: "Start from a daily recommendation, review your streak, and jump into a quick session when you want a guided routine."
        ),
        AppGuidePage(
            icon: "figure.stand",
            title: "Body Map",
            description: "Rotate the body, switch front and back, and mark areas when you want exercises for a specific spot."
        ),
        AppGuidePage(
            icon: "list.bullet",
            title: "Exercises",
            description: "Search the full library, browse by body area, and open any exercise to see targets, safety notes, and steps."
        ),
        AppGuidePage(
            icon: "wind",
            title: "Breathe",
            description: "Choose a breathing pattern, start a full session, or tap the circle to preview one round of the selected exercise."
        ),
        AppGuidePage(
            icon: "rectangle.stack",
            title: "Routines",
            description: "Build your own routines, borrow shared ones, or start a guided program."
        ),
        AppGuidePage(
            icon: "person.circle",
            title: "Profile",
            description: "Track streaks, points, and badges, manage reminders, and restart this tutorial anytime from Settings."
        )
    ]
}
