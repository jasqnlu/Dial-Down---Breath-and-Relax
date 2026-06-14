import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var showEmailAuth = false
    @State private var appleError: String?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemTeal).opacity(0.35), Color(.systemIndigo).opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Hero
                VStack(spacing: 16) {
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundStyle(.white)
                        .shadow(color: Color.primary.opacity(0.15), radius: 8, y: 4)

                    Text("Breath")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Relax. Stretch. Breathe.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // MARK: Sign-in buttons
                VStack(spacing: 14) {

                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
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
                    .frame(height: 54)
                    .cornerRadius(14)

                    // Sign in with Google (not yet implemented — real OAuth required)
                    Button {} label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color(red: 0.92, green: 0.26, blue: 0.21).opacity(0.4))
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary.opacity(0.4))
                            Spacer()
                            Text("Coming Soon")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemFill), in: Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .padding(.horizontal, 16)
                        .background(Color(.systemBackground).opacity(0.7))
                        .cornerRadius(14)
                    }
                    .disabled(true)

                    // Email / Password
                    Button {
                        showEmailAuth = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.title3)
                            Text("Continue with Email")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white.opacity(0.2))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.45), lineWidth: 1)
                        )
                    }

                    if let err = appleError {
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
                    .padding(.top, 20)
                    .padding(.bottom, 44)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
                .environmentObject(auth)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
}
