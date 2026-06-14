import SwiftUI

// MARK: - Body Map Intro Page

struct BodyMapIntroPage: View {
    private let bullets: [(icon: String, text: String)] = [
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
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, 28)

                Text("Your Personal Body Map")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(
                    "The Body Map is your interactive canvas. Tap any muscle group to instantly discover stretches and breathing exercises targeted to that area. Add annotations to track tension hotspots and watch them resolve as you build your practice."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(bullets, id: \.text) { bullet in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: bullet.icon)
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 28)

                            Text(bullet.text)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground)))
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
