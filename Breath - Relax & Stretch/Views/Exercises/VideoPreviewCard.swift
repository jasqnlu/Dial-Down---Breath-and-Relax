import SwiftUI
import AVKit
import WebKit

// MARK: - Video preview card

/// Renders the right player for an exercise's video link and an
/// "Open in <platform>" affordance. YouTube / Vimeo / generic web links play in
/// an embedded `WKWebView`; raw video files play in `AVPlayer`.
struct VideoPreviewCard: View {
    let source: VideoSource

    /// Optional title shown above the player (defaults to "Watch").
    var title: String = "Watch"

    @State private var directPlayer: AVPlayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: "play.rectangle.fill")
                    .font(.headline)
                Spacer()
                PlatformBadge(source: source)
            }
            .padding(.horizontal)

            player
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

            if let external = source.externalURL {
                Link(destination: external) {
                    Label("Open in \(source.platformName)", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal)
            }
        }
        .onDisappear {
            directPlayer?.pause()
            directPlayer = nil
        }
    }

    @ViewBuilder
    private var player: some View {
        switch source {
        case .directFile(let url):
            VideoPlayer(player: directPlayer)
                .onAppear {
                    if directPlayer == nil { directPlayer = AVPlayer(url: url) }
                }
        case .youTube, .vimeo, .web:
            WebVideoPlayerView(source: source)
        }
    }
}

// MARK: - Platform badge

/// Small coloured pill identifying the video host (red YouTube, blue Vimeo…).
struct PlatformBadge: View {
    let source: VideoSource

    private var tint: Color {
        switch source {
        case .youTube:   return .red
        case .vimeo:     return Color(red: 0.10, green: 0.66, blue: 0.93)
        case .directFile: return .accentColor
        case .web:       return .secondary
        }
    }

    var body: some View {
        Label(source.platformName, systemImage: source.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
            .accessibilityLabel("Plays on \(source.platformName)")
    }
}

// MARK: - Embedded web player

/// Plays YouTube / Vimeo / generic web video links inside a `WKWebView`.
///
/// For YouTube and Vimeo we load a small responsive HTML wrapper around the
/// platform's iframe so playback stays inline (`playsinline`) and fills the
/// card. Any other page is loaded directly.
struct WebVideoPlayerView: UIViewRepresentable {
    let source: VideoSource

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        // Let the embed's own play button start playback; nothing autoplays
        // because the embed URLs don't request autoplay.
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedSource != source else { return }
        context.coordinator.loadedSource = source

        switch source {
        case .youTube, .vimeo:
            guard let embed = source.embedURL else { return }
            // A non-nil http base URL keeps the iframe's referrer checks happy.
            let base = embed.host.flatMap { URL(string: "https://\($0)") }
            webView.loadHTMLString(Self.iframeHTML(embed: embed), baseURL: base)
        case .web(let url):
            webView.load(URLRequest(url: url))
        case .directFile:
            break
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        /// Avoids reloading (and interrupting playback) on every SwiftUI update.
        var loadedSource: VideoSource?
    }

    private static func iframeHTML(embed: URL) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { height: 100%; background: #000; overflow: hidden; }
            .wrap { position: relative; width: 100%; height: 100%; }
            iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
        </style>
        </head>
        <body>
            <div class="wrap">
                <iframe src="\(embed.absoluteString)"
                        allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture; web-share"
                        allowfullscreen></iframe>
            </div>
        </body>
        </html>
        """
    }
}
