import SwiftUI
import WebKit

// MARK: - LegalDocument

/// The two bundled legal documents required for auto-renewing subscriptions
/// (App Store Guideline 3.1.2). HTML sources live in the "Legal" folder and
/// are placeholders — see the comment at the top of each file.
enum LegalDocument: String, Identifiable {
    case termsOfUse
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .termsOfUse: return "Terms of Use"
        case .privacyPolicy: return "Privacy Policy"
        }
    }

    var resourceName: String {
        switch self {
        case .termsOfUse: return "TermsOfUse"
        case .privacyPolicy: return "PrivacyPolicy"
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
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
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
