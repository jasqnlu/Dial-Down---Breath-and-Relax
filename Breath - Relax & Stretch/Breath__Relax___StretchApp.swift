import SwiftUI
import SwiftData

@main
struct BreathRelaxStretchApp: App {
    @StateObject private var auth = AuthManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BodyPart.self,
            Exercise.self,
            Routine.self,
            Session.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .onAppear { seedIfNeeded() }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Seed exercises

    private func seedIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Exercise>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        guard
            let url  = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let exercises = json["exercises"] as? [[String: Any]]
        else { return }

        for raw in exercises {
            guard
                let name         = raw["name"] as? String,
                let typeStr      = raw["type"] as? String,
                let type         = ExerciseType(rawValue: typeStr.capitalized),
                let parts        = raw["targetBodyParts"] as? [String],
                let duration     = raw["durationSeconds"] as? Int,
                let difficulty   = raw["difficulty"] as? Int,
                let instructions = raw["instructions"] as? [String]
            else { continue }

            let mediaURL = raw["mediaURL"] as? String
            context.insert(Exercise(
                name: name, type: type, targetBodyParts: parts,
                durationSeconds: duration, difficulty: difficulty,
                instructions: instructions, mediaURL: mediaURL
            ))
        }
        try? context.save()
    }
}

// MARK: - Root routing view

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if !auth.isSignedIn {
                AuthView()
            } else if auth.needsTwoFactor {
                TwoFactorView()
            } else {
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.35), value: auth.needsTwoFactor)
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn { ensureUserProfile() }
        }
        .onAppear {
            if auth.isSignedIn { ensureUserProfile() }
        }
    }

    // MARK: - Create profile on first sign-in

    private func ensureUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let existing = try? modelContext.fetch(descriptor), existing.isEmpty else { return }
        let name = auth.displayName.isEmpty ? "User" : auth.displayName
        let profile = UserProfile(profileID: auth.userEmail, displayName: name)
        modelContext.insert(profile)
        try? modelContext.save()
    }
}
