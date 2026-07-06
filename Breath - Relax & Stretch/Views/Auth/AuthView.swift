import SwiftUI
import AuthenticationServices

// MARK: - AuthView
// Guest-first welcome screen. The primary action starts using the app with no
// account (continueAsGuest); Apple / Google / Email sign-in are offered as the
// quieter secondary path for people who want their name on their profile.

struct AuthView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var showEmailAuth = false
    @State private var appleError: String?
    @State private var googleError: String?
    @State private var isBreathingIn = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemTeal).opacity(0.35), Color(.systemIndigo).opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Hero — a circle that breathes
                VStack(spacing: 20) {
                    breathingHalo

                    Text("Breath")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Relax. Stretch. Breathe.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                VStack(spacing: 14) {
                    // MARK: Primary — use the app right now, no account.
                    // Hidden when a guest re-opens this screen to add an
                    // account (they're already "in").
                    if !auth.isGuest {
                        Button {
                            auth.continueAsGuest()
                        } label: {
                            Text("Start breathing")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(.systemIndigo))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white)
                                .cornerRadius(16)
                        }

                        // MARK: Divider
                        HStack(spacing: 12) {
                            line
                            Text("or save your progress")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .fixedSize()
                            line
                        }
                        .padding(.vertical, 2)
                    }

                    // MARK: Secondary — account options
                    SignInWithAppleButton(.signIn) { request in
                        // Sets scopes + a nonce so the identity token can be
                        // exchanged with Supabase Auth without replay risk.
                        AuthManager.shared.prepareAppleSignInRequest(request)
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                AuthManager.shared.handleAppleCredential(credential)
                            }
                        case .failure(let error):
                            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                                appleError = error.localizedDescription
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 48)
                    .cornerRadius(14)

                    HStack(spacing: 12) {
                        secondaryButton(
                            icon: "g.circle.fill",
                            title: GoogleAuthService.isConfigured ? "Google" : "Google (soon)",
                            enabled: GoogleAuthService.isConfigured
                        ) {
                            Task { await signInWithGoogle() }
                        }

                        secondaryButton(icon: "envelope.fill", title: "Email", enabled: true) {
                            showEmailAuth = true
                        }
                    }

                    if let err = appleError ?? googleError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)

                // MARK: Legal
                Text("By continuing you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
                .environmentObject(auth)
        }
        // When shown as a sheet over a guest session, close once the guest
        // upgrades to a real provider. (At the root this view is swapped out
        // by RootView instead, so dismiss() is a harmless no-op there.)
        .onChange(of: auth.provider) { _, newProvider in
            if newProvider != .guest { dismiss() }
        }
        .onAppear {
            guard !reduceMotion else { return }
            isBreathingIn = true
        }
    }

    // MARK: - Pieces

    /// Concentric circles that swell and settle at a calm breath cadence.
    /// The animation is scoped via .animation(value:) — a global
    /// withAnimation(.repeatForever) would leak into every concurrent
    /// layout change on screen, forever.
    private var breathingHalo: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 150, height: 150)
                .scaleEffect(isBreathingIn ? 1.18 : 0.92)
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 112, height: 112)
                .scaleEffect(isBreathingIn ? 1.1 : 0.94)
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(.white)
        }
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isBreathingIn)
        .frame(width: 180, height: 180)
        .accessibilityHidden(true)
    }

    private var line: some View {
        Rectangle()
            .fill(.white.opacity(0.3))
            .frame(height: 1)
    }

    private func secondaryButton(icon: String, title: String, enabled: Bool,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(enabled ? 1 : 0.45))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white.opacity(0.16))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
        }
        .disabled(!enabled)
    }

    private func signInWithGoogle() async {
        guard let anchor = ASPresentationAnchor.currentWindow else { return }
        do {
            let user = try await GoogleAuthService.shared.signIn(presentationAnchor: anchor)
            googleError = nil
            auth.handleGoogleSignIn(name: user.name, email: user.email)
        } catch GoogleAuthService.GoogleAuthError.cancelled {
            // User dismissed the sheet — not an error worth surfacing.
        } catch {
            googleError = error.localizedDescription
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
}
