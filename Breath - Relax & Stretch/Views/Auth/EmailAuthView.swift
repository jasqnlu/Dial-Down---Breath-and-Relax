import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var isSignUp   = true
    @State private var name       = ""
    @State private var email      = ""
    @State private var password   = ""
    @State private var confirmPwd = ""
    @State private var errorMsg: String?
    @State private var isLoading  = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.tint)
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.title2.bold())
                        Text(isSignUp ? "Sign up with your email address." : "Sign in to your account.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Fields
                    VStack(spacing: 14) {
                        if isSignUp {
                            AuthField(label: "Full Name", text: $name,
                                      icon: "person", contentType: .name)
                        }

                        AuthField(label: "Email", text: $email,
                                  icon: "envelope", contentType: .emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                        AuthField(label: "Password", text: $password,
                                  icon: "lock", contentType: .password, isSecure: true)

                        if isSignUp {
                            AuthField(label: "Confirm Password", text: $confirmPwd,
                                      icon: "lock.rotation", contentType: .newPassword, isSecure: true)
                        }
                    }

                    // Error
                    if let err = errorMsg {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(err)
                        }
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Primary action
                    Button {
                        submit()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.tint)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)

                    // Toggle sign in / sign up
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp.toggle()
                            errorMsg = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Submit

    private func submit() {
        errorMsg = nil
        isLoading = true

        if isSignUp {
            guard password == confirmPwd else {
                errorMsg = "Passwords do not match."
                isLoading = false
                return
            }
            if let err = auth.signUp(name: name, email: email, password: password) {
                errorMsg = err
            } else {
                dismiss()
            }
        } else {
            if let err = auth.signIn(email: email, password: password) {
                errorMsg = err
            } else {
                dismiss()
            }
        }
        isLoading = false
    }
}

// MARK: - Reusable field

private struct AuthField: View {
    let label: String
    @Binding var text: String
    let icon: String
    var contentType: UITextContentType? = nil
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField(label, text: $text)
                } else {
                    TextField(label, text: $text)
                }
            }
            .textContentType(contentType)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AuthManager.shared)
}
