import SwiftUI

struct SessionSummaryView: View {
    let pointsEarned: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close")
                Spacer()
            }
            .padding([.horizontal, .top])

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 88, height: 88)
                .background(Color.luminaCardFill, in: Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 16, y: 8)

            VStack(spacing: 8) {
                Text("Session Complete!")
                    .font(.luminaHeadline)
                    .foregroundStyle(Color.luminaPrimary)

                Text("Great work. Keep the streak going!")
                    .font(.luminaSubheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Image(systemName: "medal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.luminaOrange)
                Text("+\(pointsEarned)")
                    .font(.luminaHeadline)
                    .foregroundStyle(Color.luminaPrimary)
                Text("points earned")
                    .font(.luminaLabel)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .textCase(.uppercase)
            }
            .luminaCard()

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LuminaPillButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(colors: [Color.luminaMintTint, Color.luminaSurface],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    SessionSummaryView(pointsEarned: 42) {}
}
