import SwiftUI

// MARK: - Root Gate

struct OnboardingGate<Content: View>: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // The coach-mark tour used to auto-start here off a global flag. It is
        // now per-account and started by RegistrationGate, so an unregistered
        // account on an already-onboarded device replays it.
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
    @AppStorage("onboardingAreas")        private var onboardingAreas = ""

    @State private var currentPage = 0
    private enum Page {
        static let showcase = 2...4
        static let goals = 5
        static let total = 9
    }
    private var totalPages: Int { Page.total }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                LanguagePage().tag(0)
                WelcomePage().tag(1)

                ShowcasePage(imageName: "showcase-bodymap",
                             title: "Tap a muscle, get the stretch",
                             subtitle: "Explore the 3D Body Map to find exercises for exactly where you feel tight.")
                    .tag(2)
                ShowcasePage(imageName: "showcase-exercises",
                             title: "200+ guided exercises",
                             subtitle: "Browse animated demos with clear, step-by-step instructions.")
                    .tag(3)
                ShowcasePage(imageName: "showcase-routines",
                             title: "Build your routine",
                             subtitle: "Save your favorites, keep your streak, and earn badges.")
                    .tag(4)

                GoalPickerPage(selectedGoals: onboardingGoalsBinding).tag(Page.goals)
                FocusAreaPickerPage(selectedAreas: onboardingAreasBinding).tag(6)
                BodyMapIntroPage().tag(7)
                NotificationsPage(onComplete: completeOnboarding).tag(8)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom overlay: dots + Next button (every page except the last);
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
        .overlay(alignment: .topTrailing) {
            if Page.showcase.contains(currentPage) {
                Button("Skip") {
                    withAnimation { currentPage = Page.goals }
                }
                .font(.luminaLabel)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
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
