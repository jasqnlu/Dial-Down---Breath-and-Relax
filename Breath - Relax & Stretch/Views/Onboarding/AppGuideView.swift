import SwiftUI

// MARK: - App Guide
//
// A short, replayable tour of the app's tabs. Shown once automatically
// right after onboarding completes (see OnboardingGate in OnboardingView.swift),
// and reachable anytime afterward from Profile → Settings → Help.

struct AppGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = AppGuideContent.pages

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
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .padding(20)
            }
            .accessibilityLabel("Skip tour")

            VStack(spacing: 20) {
                Spacer()
                PageDotsIndicator(total: pages.count, current: currentPage)

                Button(action: advance) {
                    HStack(spacing: 6) {
                        Text(currentPage == pages.count - 1 ? "Start Exploring" : "Next")
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuminaPillButtonStyle())
                .padding(.horizontal, 28)
            }
            .padding(.bottom, 44)
            .allowsHitTesting(true)
        }
        .background(Color.luminaSurface.ignoresSafeArea())
    }

    private func guidePage(_ page: AppGuidePage) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)

            Image(systemName: page.icon)
                .font(.system(size: 72))
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 140, height: 140)
                .background(Color.luminaMintTint)
                .clipShape(Circle())

            Text(page.title)
                .font(.luminaDisplay)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.luminaBody)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
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
