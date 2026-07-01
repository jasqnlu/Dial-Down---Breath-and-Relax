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
                .font(.system(size: 80))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Session Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Great work. Keep the streak going!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Text("+\(pointsEarned)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                Text("points earned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    SessionSummaryView(pointsEarned: 42) {}
}
