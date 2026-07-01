import Foundation

/// Describes how an exercise's `mediaURL` string should be played.
///
/// `AVPlayer` can only stream raw video files (.mp4/.m3u8…), so links to
/// YouTube, Vimeo or any other web page have to be played inside an embedded
/// `WKWebView` instead. `VideoSource` parses a URL string once and tells the UI
/// which player to use, how to embed it, and where to open it externally.
enum VideoSource: Equatable {
    /// A YouTube video, identified by its 11-character video id.
    case youTube(id: String)
    /// A Vimeo video, identified by its numeric id.
    case vimeo(id: String)
    /// A direct video file (mp4/mov/m3u8…) that `AVPlayer` can stream.
    case directFile(URL)
    /// Any other `http(s)` page — played by loading it in a web view.
    case web(URL)

    // MARK: - Parsing

    /// Builds a `VideoSource` from a stored URL string, or `nil` when the
    /// string is empty / not a usable `http(s)` link.
    init?(urlString: String?) {
        guard
            let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty,
            let url = URL(string: raw),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else { return nil }

        let host = (url.host ?? "")
            .lowercased()
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: "m.", with: "")

        // 1. Direct video file → AVPlayer.
        if Self.videoFileExtensions.contains(url.pathExtension.lowercased()) {
            self = .directFile(url)
            return
        }

        // 2. YouTube (incl. youtu.be, Shorts, embed and -nocookie variants).
        if host.hasSuffix("youtube.com")
            || host == "youtu.be"
            || host.hasSuffix("youtube-nocookie.com") {
            if let id = Self.youTubeID(from: url) {
                self = .youTube(id: id)
                return
            }
        }

        // 3. Vimeo.
        if host.hasSuffix("vimeo.com") {
            if let id = Self.vimeoID(from: url) {
                self = .vimeo(id: id)
                return
            }
        }

        // 4. Anything else playable in a web view.
        self = .web(url)
    }

    private static let videoFileExtensions: Set<String> = ["mp4", "mov", "m4v", "m3u8", "webm"]

    /// Extracts a YouTube id from the many link shapes YouTube hands out:
    /// `watch?v=ID`, `youtu.be/ID`, `/embed/ID`, `/shorts/ID`, `/live/ID`, `/v/ID`.
    private static func youTubeID(from url: URL) -> String? {
        let host = (url.host ?? "").lowercased()

        // Short form: youtu.be/<id>
        if host.contains("youtu.be") {
            return url.pathComponents.dropFirst().first.flatMap(sanitizedID)
        }

        // watch?v=<id>
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let v = components?.queryItems?.first(where: { $0.name == "v" })?.value {
            return sanitizedID(v)
        }

        // Path-based forms: /embed/<id>, /shorts/<id>, /live/<id>, /v/<id>
        let parts = url.pathComponents.filter { $0 != "/" }
        if let keywordIndex = parts.firstIndex(where: { ["embed", "shorts", "live", "v"].contains($0) }),
           keywordIndex + 1 < parts.count {
            return sanitizedID(parts[keywordIndex + 1])
        }

        return nil
    }

    /// Extracts a numeric Vimeo id from `vimeo.com/<id>` or
    /// `player.vimeo.com/video/<id>`.
    private static func vimeoID(from url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        return parts.last(where: { Int($0) != nil })
    }

    /// Keeps only the characters valid in a video id (alphanumerics, `-`, `_`).
    private static func sanitizedID(_ raw: String) -> String? {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let id = raw.unicodeScalars.prefix { allowed.contains($0) }
        let result = String(String.UnicodeScalarView(id))
        return result.isEmpty ? nil : result
    }

    // MARK: - Presentation

    /// `true` when this source must be played in a `WKWebView` rather than `AVPlayer`.
    var requiresWebPlayer: Bool {
        if case .directFile = self { return false }
        return true
    }

    /// Human-readable platform name, e.g. for an "Open in YouTube" button.
    var platformName: String {
        switch self {
        case .youTube:   return "YouTube"
        case .vimeo:     return "Vimeo"
        case .directFile: return "Video"
        case .web:       return "Browser"
        }
    }

    /// SF Symbol representing the source.
    var symbolName: String {
        switch self {
        case .youTube, .vimeo: return "play.rectangle.fill"
        case .directFile:      return "film.fill"
        case .web:             return "safari.fill"
        }
    }

    /// Embeddable URL for the web player. Uses privacy-friendly
    /// `youtube-nocookie.com` and `playsinline` so playback stays inside the
    /// card instead of forcing fullscreen. `nil` for direct files.
    var embedURL: URL? {
        switch self {
        case .youTube(let id):
            return URL(string: "https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&rel=0&modestbranding=1")
        case .vimeo(let id):
            return URL(string: "https://player.vimeo.com/video/\(id)?playsinline=1&dnt=1")
        case .web(let url):
            return url
        case .directFile:
            return nil
        }
    }

    /// Canonical URL to open in the platform's app or the browser.
    var externalURL: URL? {
        switch self {
        case .youTube(let id):              return URL(string: "https://www.youtube.com/watch?v=\(id)")
        case .vimeo(let id):                return URL(string: "https://vimeo.com/\(id)")
        case .directFile(let url),
             .web(let url):                 return url
        }
    }
}
