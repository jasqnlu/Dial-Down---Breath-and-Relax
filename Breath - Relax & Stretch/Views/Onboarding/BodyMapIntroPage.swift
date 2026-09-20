import SwiftUI

// MARK: - Body Map Intro Page

struct BodyMapIntroPage: View {
    private let bullets: [(icon: String, text: LocalizedStringKey)] = [
        ("hand.tap.fill",
         "Tap any body region to explore targeted exercises"),
        ("pencil.and.outline",
         "Draw annotations to mark areas of tension or discomfort"),
        ("arrow.triangle.2.circlepath",
         "Your map updates as you complete sessions over time"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                Image(systemName: "figure.stand")
                    .font(.system(size: 90))
                    .foregroundStyle(Color.luminaPrimary)
                    .padding(.bottom, 28)

                Text("Your Personal Body Map")
                    .font(.luminaDisplay)
                    .foregroundStyle(Color.luminaOnSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(
                    "The Body Map is your interactive canvas. Tap any muscle group to instantly discover stretches and breathing exercises targeted to that area. Add annotations to track tension hotspots and watch them resolve as you build your practice."
                )
                .font(.luminaBody)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(bullets, id: \.icon) { bullet in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: bullet.icon)
                                .font(.title3)
                                .foregroundStyle(Color.luminaPrimary)
                                .frame(width: 28)

                            Text(bullet.text)
                                .font(.luminaSubheadline)
                                .foregroundStyle(Color.luminaOnSurface)
                        }
                    }
                }
                .luminaCard(padding: 20)
                .padding(.horizontal, 20)
                .padding(.top, 36)

                Spacer(minLength: 160)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Preview

#Preview { BodyMapIntroPage() }
