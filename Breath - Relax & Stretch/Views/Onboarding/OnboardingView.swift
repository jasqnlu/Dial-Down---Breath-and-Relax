import SwiftUI

// MARK: - Root Gate

struct OnboardingGate<Content: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if hasCompletedOnboarding {
            content
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Main OnboardingView

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboardingGoals")        private var onboardingGoals = ""

    @State private var currentPage = 0
    private let totalPages = 4

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                GoalPickerPage(selectedGoals: onboardingGoalsBinding)
                    .tag(1)

                BodyMapIntroPage()
                    .tag(2)

                NotificationsPage(onComplete: completeOnboarding)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom overlay: dots + Next button (pages 0-2);
            // page 3 provides its own action buttons.
            if currentPage < 3 {
                VStack(spacing: 20) {
                    PageDotsIndicator(total: totalPages, current: currentPage)

                    Button(action: advancePage) {
                        HStack(spacing: 6) {
                            Text("Next").fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 44)
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 160)
                    .allowsHitTesting(false),
                    alignment: .bottom
                )
                .transition(.opacity)
            }
        }
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
                    .fill(index == current ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: index == current ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") { OnboardingView() }
