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
        }
        .modelContainer(sharedModelContainer)
    }
}
