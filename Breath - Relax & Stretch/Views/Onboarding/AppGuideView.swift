import SwiftUI

// MARK: - App Guide
//
// A short, replayable tour of the app's 5 tabs. Shown once automatically
// right after onboarding completes (see OnboardingGate in OnboardingView.swift),
// and reachable anytime afterward from Profile → Settings → Help.

struct AppGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private struct GuidePage: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
    }

    // Mirrors CustomTabBar's tab order, icons, and labels.
    private let pages: [GuidePage] = [
        GuidePage(icon: "figure.stand",
                  title: "Body Map",
                  description: "Tap any body part to find exercises that target it. Switch between Skin, Muscle, and Skeleton views, or mark sore spots with the drawing tool."),
        GuidePage(icon: "list.bullet",
                  title: "Exercises",
                  description: "Browse the full library, or check For You for picks based on the goals you chose during setup."),
        GuidePage(icon: "wind",
                  title: "Breathe",
                  description: "Follow guided breathing patterns like Box Breathing and 4-7-8 to calm down in just a few minutes."),
        GuidePage(icon: "rectangle.stack",
                  title: "Routines",
                  description: "Build your own routines, borrow ones from the community, or start a guided program."),
        GuidePage(icon: "person.circle",
                  title: "Profile",
                  description: "Track streaks, points, and badges, manage reminders, and replay this tour anytime from Settings."),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    guidePage(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            .accessibilityLabel("Skip tour")

            VStack(spacing: 20) {
                Spacer()
                PageDotsIndicator(total: pages.count, current: currentPage)

                Button(action: advance) {
                    HStack(spacing: 6) {
                        Text(currentPage == pages.count - 1 ? "Start Exploring" : "Next")
                            .fontWeight(.semibold)
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                        }
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
            .allowsHitTesting(true)
        }
    }

    private func guidePage(_ page: GuidePage) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)

            Image(systemName: page.icon)
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)
                .frame(width: 140, height: 140)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Circle())

            Text(page.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer(minLength: 160)
        }
    }

    private func advance() {
        if currentPage == pages.count - 1 {
            dismiss()
        } else {
            withAnimation { currentPage += 1 }
        }
    }
}

// MARK: - Preview

#Preview { AppGuideView() }
