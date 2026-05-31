import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingPlayer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Meta info
                HStack(spacing: 16) {
                    StatChip(icon: "clock", label: "\(exercise.durationSeconds / 60) min")
                    StatChip(icon: "chart.bar", label: difficultyLabel)
                    StatChip(icon: "figure.mind.and.body", label: exercise.type.rawValue)
                }
                .padding(.horizontal)

                Divider()

                // Target body parts
                VStack(alignment: .leading, spacing: 10) {
                    Text("Targets")
                        .font(.headline)
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(exercise.targetBodyParts, id: \.self) { part in
                                Text(part)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Divider()

                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 14) {
                    Text("Instructions")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(width: 26, height: 26)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Circle())
                            Text(step)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.vertical)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            Button {
                showingPlayer = true
            } label: {
                Label("Start Exercise", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding()
            }
            .background(.regularMaterial)
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            SessionPlayerView(exercises: [exercise])
        }
    }

    var difficultyLabel: String {
        switch exercise.difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return "–"
        }
    }
}

struct StatChip: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
