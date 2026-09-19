import SwiftUI

/// Sits between App Lock and Home. Guests pass straight through; everyone else
/// is checked against Supabase and shown the name step if unregistered. Also
/// owns the once-per-account coach-mark tour (previously `OnboardingGate`).
struct RegistrationGate<Content: View>: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var tourCoordinator: TourCoordinator
    @StateObject private var registration = RegistrationCoordinator()
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if auth.isGuest {
                content.onAppear { startTourIfFirstTime() }
            } else {
                switch registration.state {
                case .idle, .checking:
                    RegistrationCheckingView()
                case .needsName(let prefill):
                    NameEntryView(prefill: prefill) { name in submit(name) }
                case .registered:
                    content.onAppear { startTourIfFirstTime() }
                }
            }
        }
        // Re-runs when the account changes — including anonymous id → Supabase
        // uid once Sign in with Apple's async token exchange completes.
        .task(id: "\(auth.backendID)|\(auth.provider.rawValue)") { await resolve() }
    }

    // MARK: - Actions

    private func resolve() async {
        guard auth.isSignedIn, !auth.isGuest else { return }
        let outcome = await registration.resolve(
            userID: auth.backendID,
            local: auth.personName,
            providerPrefill: auth.providerPrefill,
            hasBackendSession: { auth.isBackendAuthenticated || !SupabaseService.isConfigured }
        )
        if case .registered(let name, _)? = outcome {
            // A returning registered account: restore the name locally and
            // don't replay the tour.
            auth.setName(name)
            AppGuideSeen.markSeen(userID: auth.backendID)
        }
    }

    private func submit(_ name: PersonName) {
        auth.setName(name)
        let uid = auth.backendID
        Task { await registration.completeName(name, userID: uid) }
    }

    private func startTourIfFirstTime() {
        let uid = auth.backendID
        if auth.isGuest { AppGuideSeen.migrateLegacy(userID: uid) }
        guard !AppGuideSeen.isSeen(userID: uid) else { return }
        AppGuideSeen.markSeen(userID: uid)
        // The tour runs live in HomeView's own ZStack (it switches real tabs
        // underneath itself), so it can only start once Home is on screen.
        tourCoordinator.restart()
    }
}

private struct RegistrationCheckingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.luminaPrimary)
            Text("Setting things up…")
                .font(.luminaSubheadline)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.luminaSurface.ignoresSafeArea())
    }
}
