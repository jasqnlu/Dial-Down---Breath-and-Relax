import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var router: DeepLinkRouter
    @Query private var exercises: [Exercise]
    @AppStorage("onboardingGoals") private var goalsStr = ""

    private var pendingActionBinding: Binding<DeepLinkAction?> {
        Binding(get: { router.pendingAction }, set: { router.pendingAction = $0 })
    }

    var body: some View {
        TabView {
            BodyMapView()
                .tabItem {
                    Label("Body", systemImage: "figure.stand")
                }

            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet")
                }

            BreathingView()
                .tabItem {
                    Label("Breathe", systemImage: "wind")
                }

            RoutineListView()
                .tabItem {
                    Label("Routines", systemImage: "rectangle.stack")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .sheet(item: pendingActionBinding) { action in
            switch action {
            case .quickSession:
                SessionPlayerView(exercises: quickSessionExercises())
            case .importRoutine(let payload):
                ImportRoutineView(payload: payload) {
                    router.pendingAction = nil
                }
            case .viewChallenge(let payload):
                ChallengeInviteView(
                    payload: payload,
                    onAccept: { router.pendingAction = .quickSession },
                    onDismiss: { router.pendingAction = nil }
                )
            }
        }
    }

    private func quickSessionExercises() -> [Exercise] {
        let ids = Set(goalsStr.split(separator: ",").map(String.init))
        let recommended = GoalMeta.recommend(from: exercises, activeGoalIDs: ids, limit: 4)
        return recommended.isEmpty ? Array(exercises.prefix(4)) : recommended
    }
}

#Preview {
    let schema = Schema([Exercise.self, Routine.self, Session.self, UserProfile.self, BodyPart.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    HomeView()
        .modelContainer(container)
        .environmentObject(AuthManager.shared)
        .environmentObject(DeepLinkRouter())
}
