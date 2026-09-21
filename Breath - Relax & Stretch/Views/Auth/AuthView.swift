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
    /// Single error slot shared by both providers, so a new sign-in attempt
    /// always replaces whatever error (if any) the other provider left behind
    /// instead of the Apple/Google errors silently going stale next to each other.
    @State private var authError: String?
    @State private var isBreathingIn = false
    @State private var legalDocument: LegalDocument?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.luminaGradientStart, Color.luminaGradientEnd],
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
                        .font(.custom("ManropeExtraLight-ExtraBold", size: 42, relativeTo: .largeTitle))
                        .foregroundStyle(.white)

                    Text("Relax. Stretch. Breathe.")
                        .font(.luminaSubheadline)
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
                                .font(.custom("ManropeExtraLight-SemiBold", size: 18, relativeTo: .headline))
                                .foregroundStyle(Color.luminaBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white, in: Capsule())
                        }

                        // MARK: Divider
                        HStack(spacing: 12) {
                            line
                            Text("or save your progress")
                                .font(.luminaCaption)
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
                            authError = nil
                            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                AuthManager.shared.handleAppleCredential(credential)
                            }
                        case .failure(let error):
                            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                                authError = error.localizedDescription
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 48)
                    .cornerRadius(24)

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

                    if let err = authError {
                        Text(err)
                            .font(.luminaCaption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)

                // MARK: Legal
                HStack(spacing: 4) {
                    Text("By continuing you agree to our")
                        .foregroundStyle(.white.opacity(0.55))
                    Button("Terms of Use") { legalDocument = .termsOfUse }
                        .underline()
                    Text("and")
                        .foregroundStyle(.white.opacity(0.55))
                    Button("Privacy Policy") { legalDocument = .privacyPolicy }
                        .underline()
                }
                .font(.luminaCaption)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
                .environmentObject(auth)
        }
        .sheet(item: $legalDocument) { document in
            LegalDocumentView(document: document)
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

    private func secondaryButton(icon: String, title: LocalizedStringKey, enabled: Bool,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.luminaCardTitle)
            }
            .foregroundStyle(.white.opacity(enabled ? 1 : 0.45))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white.opacity(0.16), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
        }
        .disabled(!enabled)
    }

    private func signInWithGoogle() async {
        guard let anchor = ASPresentationAnchor.currentWindow else { return }
        do {
            let result = try await GoogleAuthService.shared.signIn(presentationAnchor: anchor)
            authError = await auth.handleGoogleSignIn(
                idToken: result.idToken, nonce: result.nonce,
                name: result.user.name, email: result.user.email
            )
        } catch GoogleAuthService.GoogleAuthError.cancelled {
            // User dismissed the sheet — not an error worth surfacing.
        } catch {
            authError = error.localizedDescription
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
}
