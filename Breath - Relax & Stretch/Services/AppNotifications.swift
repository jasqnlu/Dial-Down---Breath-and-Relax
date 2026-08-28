import Foundation

extension Notification.Name {
    static let browseExercisesRequested = Notification.Name("browseExercisesRequested")
    /// Posted when the user taps "Done" in the Exercises tab's picking-mode
    /// bottom bar (Views/Exercises/ExerciseListView.swift). HomeView listens
    /// to switch back to the Home tab; TodayView listens to re-present
    /// CustomizeRoutineView with the merged picks.
    static let exercisePickingFinished = Notification.Name("exercisePickingFinished")
}
