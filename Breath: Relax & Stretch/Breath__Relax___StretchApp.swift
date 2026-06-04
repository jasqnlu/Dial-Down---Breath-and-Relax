import SwiftUI
import SwiftData

@main
struct BreathRelaxStretchApp: App {
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
            HomeView()
                .onAppear { seedIfNeeded() }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Seed data

    private func seedIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Exercise>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        guard
            let url = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
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
            let exercise = Exercise(
                name: name,
                type: type,
                targetBodyParts: parts,
                durationSeconds: duration,
                difficulty: difficulty,
                instructions: instructions,
                mediaURL: mediaURL
            )
            context.insert(exercise)
        }

        try? context.save()
    }
}
