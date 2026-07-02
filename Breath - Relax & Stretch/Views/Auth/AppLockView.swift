import SwiftUI
import LocalAuthentication

// MARK: - AppLockView
// Biometric gate shown on cold launch when App Lock is enabled. This is a
// local privacy screen (Face ID / Touch ID / passcode) — deliberately NOT
// branded as "two-factor authentication", because there is no second factor:
// it locks the app, it doesn't verify an account.

struct AppLockView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var failed = false
    @State private var isAuthenticating = false

    private var biometricLabel: String {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            return ctx.biometryType == .faceID ? "Face ID" : "Touch ID"
        }
        return "Passcode"
    }

    private var biometricIcon: String {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            return ctx.biometryType == .faceID ? "faceid" : "touchid"
        }
        return "lock.fill"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemIndigo).opacity(0.45), Color(.systemTeal).opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 110, height: 110)
                    Image(systemName: biometricIcon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.primary)
                }

                // Text
                VStack(spacing: 10) {
                    Text("App Locked")
                        .font(.title2.bold())
                    Text("Use \(biometricLabel) to unlock the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                if failed {
                    Text("Couldn't unlock. Try again.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                // Unlock button
                Button {
                    unlock()
                } label: {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: biometricIcon)
                            Text("Unlock with \(biometricLabel)")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 260, height: 52)
                    .background(.tint)
                    .cornerRadius(14)
                }
                .disabled(isAuthenticating)

                // Sign out escape hatch
                Button("Sign out instead") {
                    auth.signOut()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .onAppear { unlock() }
    }

    private func unlock() {
        isAuthenticating = true
        failed = false
        Task {
            let ok = await auth.authenticateWithBiometrics()
            await MainActor.run {
                isAuthenticating = false
                if ok {
                    auth.completeUnlock()
                } else {
                    failed = true
                }
            }
        }
    }
}

#Preview {
    AppLockView()
        .environmentObject(AuthManager.shared)
}
