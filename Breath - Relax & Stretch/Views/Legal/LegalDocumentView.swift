import SwiftUI
import WebKit

// MARK: - LegalDocument

/// Bundled documents shown in-app via a WKWebView sheet. `termsOfUse` and
/// `privacyPolicy` are standard App Store legal requirements — the App has
/// no purchases of any kind, so neither document covers subscriptions or
/// IAP. `credits` fulfills the CC BY-SA 4.0 attribution requirement on the
/// body-map anatomy assets (see `ASSET_CREDITS.md` at the repo root). HTML
/// sources live in the "Legal" folder.
enum LegalDocument: String, Identifiable {
    case termsOfUse
    case privacyPolicy
    case credits

    var id: String { rawValue }

    var title: String {
        switch self {
        case .termsOfUse: return "Terms of Use"
        case .privacyPolicy: return "Privacy Policy"
        case .credits: return "Credits"
        }
    }

    var resourceName: String {
        switch self {
        case .termsOfUse: return "TermsOfUse"
        case .privacyPolicy: return "PrivacyPolicy"
        case .credits: return "Credits"
        }
    }
}

// MARK: - LegalDocumentView

/// Presents a bundled legal HTML document in a sheet with a close button.
struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LegalWebView(resourceName: document.resourceName)
                .background(Color.luminaSurface.ignoresSafeArea())
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                            .foregroundStyle(Color.luminaPrimary)
                    }
                }
        }
    }
}

// MARK: - LegalWebView

/// Thin UIViewRepresentable wrapper around WKWebView that loads a bundled
/// HTML resource by name (no extension), used for in-app legal documents.
struct LegalWebView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "html", subdirectory: "Legal")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "html")
        else { return }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

#Preview {
    LegalDocumentView(document: .termsOfUse)
}
