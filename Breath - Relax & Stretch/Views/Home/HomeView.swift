import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var router: DeepLinkRouter
    @Query private var exercises: [Exercise]
    @AppStorage("onboardingGoals") private var goalsStr = ""
    @State private var selectedTab: Int = 0

    private var pendingActionBinding: Binding<DeepLinkAction?> {
        Binding(get: { router.pendingAction }, set: { router.pendingAction = $0 })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // TabView handles lazy loading + nav-state preservation per tab.
            // The default tab bar chrome is hidden; CustomTabBar floats on top.
            TabView(selection: $selectedTab) {
                BodyMapView().tag(0)
                ExerciseListView().tag(1)
                BreathingView().tag(2)
                RoutineListView().tag(3)
                ProfileView().tag(4)
            }
            .toolbar(.hidden, for: .tabBar)
            // Add extra bottom inset so scrollable content clears the floating bar.
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }

            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard)
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
