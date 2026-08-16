/// PreviewCatalog.swift
/// Open this file in Xcode and use the canvas to jump between every screen.
/// None of this code ships in the app binary — it's #Preview only.

import SwiftUI
import SwiftData

// MARK: - Shared preview helpers

private func makeContainer() -> ModelContainer {
    let schema = Schema([Exercise.self, Routine.self, Session.self, UserProfile.self])
    return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}

private func sampleExercise() -> Exercise {
    Exercise(
        name: "Deep Belly Breath",
        type: .breath,
        targetBodyParts: ["Chest"],
        durationSeconds: 90,
        difficulty: 1,
        instructions: ["Inhale for 4s", "Hold for 4s", "Exhale for 4s"]
    )
}

private func sampleRoutine() -> Routine {
    Routine(name: "Morning Wake-Up", exerciseIDs: [])
}

// MARK: - Auth screens

#Preview("Auth – Landing") {
    AuthView()
        .environmentObject(AuthManager.shared)
}

#Preview("Auth – Email Sign Up") {
    EmailAuthView()
        .environmentObject(AuthManager.shared)
}

#Preview("Auth – App Lock") {
    AppLockView()
        .environmentObject(AuthManager.shared)
}

// MARK: - Main app

#Preview("Home (all tabs)") {
    HomeView()
        .modelContainer(makeContainer())
        .environmentObject(AuthManager.shared)
}

// MARK: - Exercises

#Preview("Exercise List") {
    ExerciseListView()
        .modelContainer(makeContainer())
}

#Preview("Exercise Detail") {
    let c = makeContainer()
    let ex = sampleExercise()
    c.mainContext.insert(ex)
    return NavigationStack {
        ExerciseDetailView(exercise: ex)
    }
    .modelContainer(c)
}

// MARK: - Routines

#Preview("Routine List") {
    RoutineListView()
        .modelContainer(makeContainer())
}

#Preview("Routine Builder") {
    RoutineBuilderView()
        .modelContainer(makeContainer())
}

// MARK: - Session

#Preview("Session Player") {
    let c = makeContainer()
    let ex = sampleExercise()
    c.mainContext.insert(ex)
    return SessionPlayerView(exercises: [ex])
        .modelContainer(c)
}

#Preview("Session Summary") {
    SessionSummaryView(pointsEarned: 50, onDismiss: {})
}

// MARK: - Profile

#Preview("Profile") {
    ProfileView()
        .modelContainer(makeContainer())
}

#Preview("Badges") {
    BadgesView(earnedBadges: ["First Session", "7-Day Streak", "Night Owl"])
}

// MARK: - Body Map

#Preview("Body Map") {
    BodyMapView()
        .modelContainer(makeContainer())
}
