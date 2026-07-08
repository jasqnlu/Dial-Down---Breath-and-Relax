import SwiftUI

// MARK: - Gender Picker Onboarding Page

struct GenderPickerPage: View {
    @AppStorage("bodyMapSex") private var bodyMapSex = "male"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Your Body Map")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Choose a body type so we can show you the right map.")
                    .font(.body)
                    .foregroundStyle(.secondary)
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
                colors: [Color(.systemBlue).opacity(0.28), Color(.systemCyan).opacity(0.12)],
                startPoint: .top, endPoint: .bottom)
            : LinearGradient(
                colors: [Color(.systemPink).opacity(0.28), Color(.systemOrange).opacity(0.12)],
                startPoint: .top, endPoint: .bottom)
    }

    private var borderColor: Color {
        isSelected ? .accentColor : Color(.systemGray5)
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
                        .font(.headline)
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 24)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
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
