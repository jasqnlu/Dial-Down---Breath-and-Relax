import SwiftUI
import SwiftData

@main
struct BreathRelaxStretchApp: App {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BodyPart.self,
            Exercise.self,
            Routine.self,
            Session.self,
            UserProfile.self,
        ])
        // .automatic = sync via iCloud when the user is signed in; falls back to
        // local-only storage if iCloud is unavailable. Requires iCloud + CloudKit
        // capabilities in Xcode → Signing & Capabilities.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("seedDataVersion") private var seedDataVersion: Int = 0

    var body: some Scene {
        WindowGroup {
            OnboardingGate {
                RootView()
            }
            .environmentObject(auth)
            .environmentObject(deepLinkRouter)
            .onAppear {
                seedIfNeeded()
                migrateSeedIfNeeded()
            }
            .task { await syncRemoteCatalog() }
            .onOpenURL { url in
                deepLinkRouter.handle(url)
            }
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
            let caution  = raw["caution"] as? String
            let exercise = Exercise(
                name: name, type: type, targetBodyParts: parts,
                durationSeconds: duration, difficulty: difficulty,
                instructions: instructions, mediaURL: mediaURL, caution: caution
            )
            if let posesRaw = raw["poses"],
               let posesData = try? JSONSerialization.data(withJSONObject: posesRaw) {
                exercise.posesData = posesData
            }
            context.insert(exercise)
        }
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("⚠️ SwiftData seed save failed: \(error)")
            #endif
        }
    }

    // MARK: - Seed migration (adds pose data to exercises seeded before v2)

    private func migrateSeedIfNeeded() {
        guard seedDataVersion < 2 else { return }

        guard
            let url  = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rawExercises = json["exercises"] as? [[String: Any]]
        else { return }

        // Build name → posesData map from bundle seed
        var posesByName: [String: Data] = [:]
        for raw in rawExercises {
            guard
                let name     = raw["name"] as? String,
                let posesRaw = raw["poses"],
                let poseData = try? JSONSerialization.data(withJSONObject: posesRaw)
            else { continue }
            posesByName[name] = poseData
        }

        let context = sharedModelContainer.mainContext
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in existing {
            if exercise.posesData.isEmpty, let poseData = posesByName[exercise.name] {
                exercise.posesData = poseData
                changed = true
            }
        }

        if changed {
            try? context.save()
        }
        seedDataVersion = 2
    }

    // MARK: - Remote catalog sync (best-effort, offline-first)

    /// After the bundled seed loads, pull the curated catalog from Supabase and
    /// upsert it into SwiftData. No-ops (silently) when the backend isn't
    /// configured or the device is offline — the seed catalog stays in place.
    @MainActor
    private func syncRemoteCatalog() async {
        guard SupabaseService.isConfigured else { return }
        do {
            let remote = try await SupabaseService.shared.fetchExercises()
            guard !remote.isEmpty else { return }
            upsertExercises(remote, into: sharedModelContainer.mainContext)
        } catch {
            // Offline or backend error — bundled seed remains the source of truth.
        }
    }

    @MainActor
    private func upsertExercises(_ remote: [RemoteExercise], into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var byID: [UUID: Exercise] = [:]
        for ex in existing { byID[ex.uuid] = ex }

        for r in remote {
            guard let id = UUID(uuidString: r.id),
                  let type = ExerciseType(rawValue: r.type.capitalized) else { continue }
            if let ex = byID[id] {
                ex.name            = r.name
                ex.type            = type
                ex.targetBodyParts = r.targetBodyParts
                ex.durationSeconds = r.durationSeconds
                ex.difficulty      = r.difficulty
                ex.instructions    = r.instructions
                ex.mediaURL        = r.mediaURL
                ex.caution         = r.caution
            } else {
                context.insert(Exercise(
                    uuid: id, name: r.name, type: type,
                    targetBodyParts: r.targetBodyParts,
                    durationSeconds: r.durationSeconds, difficulty: r.difficulty,
                    instructions: r.instructions, mediaURL: r.mediaURL, caution: r.caution
                ))
            }
        }
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("⚠️ SwiftData upsert save failed: \(error)")
            #endif
        }
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
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ SwiftData profile save failed: \(error)")
            #endif
        }
    }
}
