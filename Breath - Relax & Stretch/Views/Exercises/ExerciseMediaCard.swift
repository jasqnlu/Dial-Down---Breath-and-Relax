import SwiftUI
import AVKit

/// Hero media slot: looping local video when available, otherwise a
/// "coming soon" placeholder. Never renders a broken player.
struct ExerciseMediaCard: View {
    let exercise: Exercise
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    var body: some View {
        Group {
            if let url = exercise.localVideoURL {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        guard player == nil else { return }
                        let p = AVPlayer(url: url)
                        p.isMuted = true
                        p.actionAtItemEnd = .none
                        let token = NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: p.currentItem, queue: .main) { _ in
                                p.seek(to: .zero); p.play()
                            }
                        loopObserver = token
                        p.play()
                        player = p
                    }
                    .onDisappear {
                        player?.pause()
                        if let token = loopObserver {
                            NotificationCenter.default.removeObserver(token)
                        }
                        player = nil
                        loopObserver = nil
                    }
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
