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
            // iCloud schema conflicts after an upgrade can make the persistent store
            // fail to open. Fall back to an in-memory container so the app at least
            // launches; the user will lose synced data for this session but can
            // reopen to get a fresh persistent store on the next cold start.
            #if DEBUG
            print("⚠️ ModelContainer failed to open persistent store, falling back to in-memory: \(error)")
            #endif
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback]))
                ?? { fatalError("Could not create any ModelContainer: \(error)") }()
        }
    }()

    @AppStorage("seedDataVersion") private var seedDataVersion: Int = 0
    @AppStorage("notifiedSeedVersion") private var notifiedSeedVersion: Int = 0
    @State private var showNewContentAlert = false

    var body: some Scene {
        WindowGroup {
            OnboardingGate {
                RootView()
            }
            .environmentObject(auth)
            .environmentObject(deepLinkRouter)
            .onAppear {
                let freshInstall = seedIfNeeded()
                migrateSeedIfNeeded()
                if freshInstall {
                    // A first-ever launch already has all the content — don't
                    // greet new users with a "New Content Added" alert.
                    notifiedSeedVersion = seedDataVersion
                } else if notifiedSeedVersion < seedDataVersion {
                    showNewContentAlert = true
                }
            }
            .alert("New Content Added", isPresented: $showNewContentAlert) {
                Button("Got it") { notifiedSeedVersion = seedDataVersion }
            } message: {
                Text("Video tutorials and animated guides are now available for your exercises. Check them out in the Exercises tab.")
            }
            .task { await syncRemoteCatalog() }
            .onOpenURL { url in
                deepLinkRouter.handle(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Seed exercises

    /// Returns true when this was a fresh install (no exercises existed yet).
    @discardableResult
    private func seedIfNeeded() -> Bool {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Exercise>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return false }

        guard
            let url  = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let exercises = json["exercises"] as? [[String: Any]]
        else { return true } // still a fresh install, even if the seed failed to load

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
        return true
    }

    // MARK: - Seed migration
    // Backfills data added to the bundled seed after a user first installed:
    //   v2 — pose keyframes for the stick-figure animation
    //   v3 — video tutorial links (mediaURL) for select exercises

    private func migrateSeedIfNeeded() {
        guard seedDataVersion < 3 else { return }

        guard
            let url  = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rawExercises = json["exercises"] as? [[String: Any]]
        else { return }

        // Build name → (posesData, mediaURL) maps from the bundle seed.
        var posesByName: [String: Data] = [:]
        var mediaByName: [String: String] = [:]
        for raw in rawExercises {
            guard let name = raw["name"] as? String else { continue }
            if let posesRaw = raw["poses"],
               let poseData = try? JSONSerialization.data(withJSONObject: posesRaw) {
                posesByName[name] = poseData
            }
            if let media = raw["mediaURL"] as? String, !media.isEmpty {
                mediaByName[name] = media
            }
        }

        let context = sharedModelContainer.mainContext
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var changed = false
        for exercise in existing {
            if exercise.posesData.isEmpty, let poseData = posesByName[exercise.name] {
                exercise.posesData = poseData
                changed = true
            }
            // Only fill in a video when the exercise doesn't already have one,
            // so we never clobber a link the user added themselves.
            if (exercise.mediaURL ?? "").isEmpty, let media = mediaByName[exercise.name] {
                exercise.mediaURL = media
                changed = true
            }
        }

        if changed {
            try? context.save()
        }
        seedDataVersion = 3
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
            } else if auth.needsUnlock {
                AppLockView()
            } else {
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.35), value: auth.needsUnlock)
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
        // Keyed by the anonymous UUID so guest and signed-in users work the
        // same way, and the email never doubles as an identifier.
        let profile = UserProfile(profileID: auth.anonymousID, displayName: name)
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
