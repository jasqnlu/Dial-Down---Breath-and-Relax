import Foundation
import Combine

// MARK: - DeepLinkAction

enum DeepLinkAction: Identifiable {
    case quickSession
    case importRoutine(RoutineSharePayload)
    case viewChallenge(ChallengePayload)

    var id: String {
        switch self {
        case .quickSession:
            return "quickSession"
        case .importRoutine(let payload):
            return "import-\(payload.name)-\(payload.exerciseNames.count)"
        case .viewChallenge(let payload):
            return "challenge-\(payload.fromName)-\(payload.streak)"
        }
    }
}

// MARK: - DeepLinkRouter
// Parses incoming `breath://` URLs (from the widget or a shared routine link)
// into a DeepLinkAction that HomeView observes and presents as a sheet.

final class DeepLinkRouter: ObservableObject {
    @Published var pendingAction: DeepLinkAction?

    func handle(_ url: URL) {
        guard url.scheme == "breath" else { return }

        switch url.host {
        case "quick-session":
            pendingAction = .quickSession

        case "routine":
            guard
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let data = components.queryItems?.first(where: { $0.name == "data" })?.value,
                let payload = RoutineSharePayload.decode(from: data)
            else { return }
            pendingAction = .importRoutine(payload)

        case "challenge":
            guard
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let data = components.queryItems?.first(where: { $0.name == "data" })?.value,
                let payload = ChallengePayload.decode(from: data)
            else { return }
            pendingAction = .viewChallenge(payload)

        default:
            break
        }
    }
}
