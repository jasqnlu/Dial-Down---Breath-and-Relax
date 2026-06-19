import SwiftUI

// MARK: - ChallengeInviteView
// Shown when the app is opened via a shared `breath://challenge` link.

struct ChallengeInviteView: View {
    let payload: ChallengePayload
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)

                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                Text("\(payload.fromName.isEmpty ? "A friend" : payload.fromName) challenges you!")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("They're on a \(payload.streak)-day streak with \(payload.totalPoints) points. Think you can keep up?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer(minLength: 0)

                Button(action: onAccept) {
                    Text("Accept & Start a Session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss", action: onDismiss)
                }
            }
        }
    }
}

#Preview {
    ChallengeInviteView(
        payload: ChallengePayload(fromName: "Jason", streak: 12, totalPoints: 840),
        onAccept: {}, onDismiss: {}
    )
}
