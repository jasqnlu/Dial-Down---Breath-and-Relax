import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var router: DeepLinkRouter
    @Query private var exercises: [Exercise]
    @AppStorage("onboardingGoals") private var goalsStr = ""
    @State private var selectedTab: Int = 0
    // Tabs are created on first visit and kept alive after, so nav/scroll
    // state survives switching (what TabView used to give us) without
    // TabView's 5-item UIKit limit — a 6th child spills into a "More"
    // controller even when the tab bar chrome is hidden.
    @State private var visitedTabs: Set<Int> = [0]

    private var pendingActionBinding: Binding<DeepLinkAction?> {
        Binding(get: { router.pendingAction }, set: { router.pendingAction = $0 })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                ForEach(visitedTabs.sorted(), id: \.self) { index in
                    tabContent(index)
                        .opacity(selectedTab == index ? 1 : 0)
                        .allowsHitTesting(selectedTab == index)
                        .accessibilityHidden(selectedTab != index)
                }
            }
            // Add extra bottom inset so scrollable content clears the floating bar.
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }

            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 10)
        }
        .onChange(of: selectedTab) { _, tab in
            visitedTabs.insert(tab)
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

    @ViewBuilder
    private func tabContent(_ index: Int) -> some View {
        switch index {
        case 0:  TodayView()
        case 1:  BodyMapView()
        case 2:  ExerciseListView()
        case 3:  BreathingView()
        case 4:  RoutineListView()
        default: ProfileView()
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
