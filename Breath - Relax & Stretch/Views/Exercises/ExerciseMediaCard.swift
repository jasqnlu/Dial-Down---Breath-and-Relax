import SwiftUI
import AVKit

/// Hero media slot: looping local video when available, otherwise a
/// "coming soon" placeholder. Never renders a broken player.
struct ExerciseMediaCard: View {
    let exercise: Exercise
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let url = exercise.localVideoURL {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        let p = AVPlayer(url: url)
                        p.isMuted = true
                        p.actionAtItemEnd = .none
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: p.currentItem, queue: .main) { _ in
                                p.seek(to: .zero); p.play()
                            }
                        p.play()
                        player = p
                    }
                    .onDisappear { player?.pause(); player = nil }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "video.badge.waveform")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.accentColor)
                    Text("Video coming soon")
                        .font(.subheadline.weight(.semibold))
                    Text("Follow the steps below in the meantime.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16/9, contentMode: .fit)
                .background(Color(.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
