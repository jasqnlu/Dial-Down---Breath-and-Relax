import SwiftUI

// MARK: - Welcome Page

struct WelcomePage: View {
    private struct Feature: Identifiable {
        let id   = UUID()
        let icon: String
        let title: String
        let description: String
    }

    private let features: [Feature] = [
        Feature(icon: "figure.mind.and.body",
                title: "Body Map",
                description: "Tap any muscle to find targeted exercises"),
        Feature(icon: "lungs",
                title: "Breathing Guides",
                description: "Calm your nervous system in minutes"),
        Feature(icon: "medal",
                title: "Track Progress",
                description: "Build streaks and earn badges"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // Hero icon
                Image(systemName: "lungs.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, 28)

                Text("Breath: Relax & Stretch")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Your daily guide to breathing, stretching, and feeling better.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)

                // Feature list
                VStack(spacing: 0) {
                    ForEach(features) { feature in
                        FeatureRow(icon: feature.icon,
                                   title: feature.title,
                                   description: feature.description)
                        if feature.id != features.last?.id {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground)))
                .padding(.horizontal, 20)

                Spacer(minLength: 160)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview { WelcomePage() }
