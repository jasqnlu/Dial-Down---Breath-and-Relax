import SwiftUI

struct HomeView: View {
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
    HomeView()
}
