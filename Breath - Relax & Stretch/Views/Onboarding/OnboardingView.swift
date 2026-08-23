import SwiftUI

// MARK: - Root Gate

struct OnboardingGate<Content: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenAppGuide") private var hasSeenAppGuide = false
    @EnvironmentObject private var tourCoordinator: TourCoordinator
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if hasCompletedOnboarding {
            content
                .onAppear {
                    // The tour runs live, in HomeView's own ZStack — it can't
                    // be a sheet, since it needs to switch real tabs
                    // underneath itself. `hasSeenAppGuide` only gates whether
                    // it *auto*-starts; TourCoordinator.finish() is what
                    // actually ends it later.
                    guard !hasSeenAppGuide else { return }
                    hasSeenAppGuide = true
                    tourCoordinator.restart()
                }
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Main OnboardingView

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboardingGoals")        private var onboardingGoals = ""
    @AppStorage("onboardingAreas")        private var onboardingAreas = ""

    @State private var currentPage = 0
    private let totalPages = 6

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                GenderPickerPage()
                    .tag(1)

                GoalPickerPage(selectedGoals: onboardingGoalsBinding)
                    .tag(2)

                FocusAreaPickerPage(selectedAreas: onboardingAreasBinding)
                    .tag(3)

                BodyMapIntroPage()
                    .tag(4)

                NotificationsPage(onComplete: completeOnboarding)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom overlay: dots + Next button (pages 0-4);
            // the last page provides its own action buttons.
            if currentPage < totalPages - 1 {
                VStack(spacing: 20) {
                    PageDotsIndicator(total: totalPages, current: currentPage)

                    Button(action: advancePage) {
                        HStack(spacing: 6) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LuminaPillButtonStyle())
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 44)
                .background(
                    LinearGradient(
                        colors: [Color.luminaSurface.opacity(0), Color.luminaSurface],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 160)
                    .allowsHitTesting(false),
                    alignment: .bottom
                )
                .transition(.opacity)
            }
        }
        .background(Color.luminaSurface.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Helpers

    /// Converts comma-separated `onboardingGoals` AppStorage string ↔ Set<String>.
    private var onboardingGoalsBinding: Binding<Set<String>> {
        Binding(
            get: {
                let trimmed = onboardingGoals.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return [] }
                return Set(trimmed.split(separator: ",").map(String.init))
            },
            set: { onboardingGoals = $0.sorted().joined(separator: ",") }
        )
    }

    /// Converts comma-separated `onboardingAreas` AppStorage string ↔ Set of
    /// `ExerciseCategory` raw values (the Focus-area picker's selection).
    private var onboardingAreasBinding: Binding<Set<String>> {
        Binding(
            get: {
                let trimmed = onboardingAreas.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return [] }
                return Set(trimmed.split(separator: ",").map(String.init))
            },
            set: { onboardingAreas = $0.sorted().joined(separator: ",") }
        )
    }

    private func advancePage() {
        withAnimation { currentPage = min(currentPage + 1, totalPages - 1) }
    }

    private func completeOnboarding() {
        withAnimation { hasCompletedOnboarding = true }
    }
}

// MARK: - Page Dots Indicator

struct PageDotsIndicator: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.luminaPrimary : Color.luminaOutline)
                    .frame(width: index == current ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") { OnboardingView() }
