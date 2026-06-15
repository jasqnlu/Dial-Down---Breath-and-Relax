import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingPlayer = false
    @State private var player: AVPlayer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Meta chips ──────────────────────────────────────────────
                HStack(spacing: 16) {
                    StatChip(icon: "clock",             label: exercise.durationFormatted)
                    StatChip(icon: "chart.bar",         label: difficultyLabel)
                    StatChip(icon: "figure.mind.and.body", label: exercise.type.rawValue)
                }
                .padding(.horizontal)

                // ── Safety caution (only when the exercise has one) ─────────
                if let caution = exercise.caution, !caution.isEmpty {
                    CautionCard(text: caution)
                        .padding(.horizontal)
                }

                // ── Stick figure animation ─────────────────────────────────
                if !exercise.poses.isEmpty {
                    StickFigureView(
                        poses: exercise.poses,
                        activeBodyParts: Set(exercise.targetBodyParts)
                    )
                    .frame(maxWidth: 260)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Divider()

                // ── Video / media preview ───────────────────────────────────
                if let p = player {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                            .padding(.horizontal)

                        VideoPlayer(player: p)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                    }

                    Divider()
                }

                // ── Target body parts ────────────────────────────────────────
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

                // ── Step-by-step instructions ────────────────────────────────
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

                // ── Global medical disclaimer ───────────────────────────────
                MedicalDisclaimerNote()
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer(minLength: 80)
            }
            .padding(.vertical)
        }
        .navigationTitle(exercise.name)
        .onAppear {
            if let urlString = exercise.mediaURL, let url = URL(string: urlString) {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
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
        .sheet(isPresented: $showingPlayer) {
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

// MARK: - Stat chip

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
            .accessibilityLabel(label)
    }
}
