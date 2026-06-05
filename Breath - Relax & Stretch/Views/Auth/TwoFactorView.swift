import SwiftUI
import LocalAuthentication

struct TwoFactorView: View {
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
                    Text("Two-Factor Verification")
                        .font(.title2.bold())
                    Text("Use \(biometricLabel) to verify your identity and open the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                if failed {
                    Text("Verification failed. Try again.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                // Verify button
                Button {
                    verify()
                } label: {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: biometricIcon)
                            Text("Verify with \(biometricLabel)")
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
        .onAppear { verify() }
    }

    private func verify() {
        isAuthenticating = true
        failed = false
        Task {
            let ok = await auth.authenticateWithBiometrics()
            await MainActor.run {
                isAuthenticating = false
                if ok {
                    auth.completeTwoFactor()
                } else {
                    failed = true
                }
            }
        }
    }
}

#Preview {
    TwoFactorView()
        .environmentObject(AuthManager.shared)
}
