import SwiftUI

// MARK: - Gender Picker Onboarding Page

struct GenderPickerPage: View {
    @AppStorage("bodyMapSex") private var bodyMapSex = "male"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Your Body Map")
                    .font(.luminaDisplay)
                    .foregroundStyle(Color.luminaOnSurface)
                    .multilineTextAlignment(.center)

                Text("Choose a body type so we can show you the right map.")
                    .font(.luminaBody)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer().frame(height: 44)

            HStack(spacing: 20) {
                GenderCard(sex: "male",
                           label: "Male",
                           isSelected: bodyMapSex == "male") {
                    withAnimation(.easeInOut(duration: 0.18)) { bodyMapSex = "male" }
                }

                GenderCard(sex: "female",
                           label: "Female (coming soon)",
                           isSelected: bodyMapSex == "female") {
                    withAnimation(.easeInOut(duration: 0.18)) { bodyMapSex = "female" }
                }
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
        // leave room for the floating dots + Next button
        .padding(.bottom, 120)
    }
}

// MARK: - Card

private struct GenderCard: View {
    let sex: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    private var silhouetteFill: LinearGradient {
        sex == "male"
            ? LinearGradient(
                colors: [Color.luminaBlue.opacity(0.28), Color.luminaGradientStart.opacity(0.12)],
                startPoint: .top, endPoint: .bottom)
            : LinearGradient(
                colors: [Color.luminaOrange.opacity(0.28), Color.luminaGradientEnd.opacity(0.12)],
                startPoint: .top, endPoint: .bottom)
    }

    private var borderColor: Color {
        isSelected ? .luminaPrimary : .luminaOutline
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    if sex == "male" {
                        MaleSilhouetteShape()
                            .fill(silhouetteFill)
                            .overlay(
                                MaleSilhouetteShape()
                                    .stroke(borderColor.opacity(0.7), lineWidth: 1.2)
                            )
                    } else {
                        FemaleSilhouetteShape()
                            .fill(silhouetteFill)
                            .overlay(
                                FemaleSilhouetteShape()
                                    .stroke(borderColor.opacity(0.7), lineWidth: 1.2)
                            )
                    }
                }
                .aspectRatio(0.46, contentMode: .fit)
                .frame(maxWidth: .infinity)

                HStack(spacing: 6) {
                    Text(label)
                        .font(.luminaCardTitle)
                        .foregroundStyle(isSelected ? Color.luminaPrimary : Color.luminaOnSurface)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.luminaPrimary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 24)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous)
                    .fill(Color.luminaCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Gender Picker") {
    GenderPickerPage()
}
