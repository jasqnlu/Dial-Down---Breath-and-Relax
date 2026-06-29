import SwiftUI
import AVKit
import WebKit

// MARK: - VideoSource

enum VideoSource {
    case youtube(id: String)
    case vimeo(id: String)
    case rawVideo(url: URL)
    case webLink(url: URL)

    init?(urlString: String?) {
        guard let str = urlString?.trimmingCharacters(in: .whitespaces),
              !str.isEmpty,
              let url = URL(string: str) else { return nil }
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") || host.contains("youtu.be") {
            if let id = Self.youtubeID(from: url) { self = .youtube(id: id); return }
        }
        if host.contains("vimeo.com"),
           let id = url.pathComponents.last(where: { !$0.isEmpty && $0 != "/" }) {
            self = .vimeo(id: id); return
        }
        if ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased()) {
            self = .rawVideo(url: url); return
        }
        self = .webLink(url: url)
    }

    private static func youtubeID(from url: URL) -> String? {
        if url.host?.contains("youtu.be") == true { return url.pathComponents.dropFirst().first }
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let v = comps.queryItems?.first(where: { $0.name == "v" })?.value { return v }
        if let idx = url.pathComponents.firstIndex(of: "embed"),
           idx + 1 < url.pathComponents.count { return url.pathComponents[idx + 1] }
        return nil
    }

    var embedURL: URL? {
        switch self {
        case .youtube(let id): return URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1")
        case .vimeo(let id):   return URL(string: "https://player.vimeo.com/video/\(id)?playsinline=1")
        default:               return nil
        }
    }
}

// MARK: - VideoPreviewCard

struct VideoPreviewCard: View {
    let source: VideoSource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.headline)
                .padding(.horizontal)

            switch source {
            case .rawVideo(let url):
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

            case .youtube, .vimeo:
                if let embedURL = source.embedURL {
                    WebEmbedView(url: embedURL)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                }

            case .webLink(let url):
                Link(destination: url) {
                    Label("Watch Video", systemImage: "play.rectangle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
            }
        }
    }
}

private struct WebEmbedView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.backgroundColor = .black
        wv.scrollView.isScrollEnabled = false
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        wv.load(URLRequest(url: url))
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var showingPlayer = false

    /// Resolved video link (YouTube / Vimeo / file / web), if the exercise has one.
    private var videoSource: VideoSource? {
        VideoSource(urlString: exercise.mediaURL)
    }

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
                // Plays YouTube, Vimeo, other platforms (web view) or a raw
                // video file (AVPlayer), depending on the exercise's link.
                if let videoSource {
                    VideoPreviewCard(source: videoSource)
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
