import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        TabView {
            BodyMapView()
                .tabItem {
                    Label("Body", systemImage: "figure.stand")
                }

            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet")
                }

            BreathingView()
                .tabItem {
                    Label("Breathe", systemImage: "wind")
                }

            RoutineListView()
                .tabItem {
                    Label("Routines", systemImage: "rectangle.stack")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    let schema = Schema([Exercise.self, Routine.self, Session.self, UserProfile.self, BodyPart.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    HomeView()
        .modelContainer(container)
}
