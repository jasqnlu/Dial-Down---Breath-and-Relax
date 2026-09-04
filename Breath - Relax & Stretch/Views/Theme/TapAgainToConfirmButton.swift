import SwiftUI
import UIKit

/// A button that requires a second tap within `confirmWindow` to actually
/// fire its action — a lighter, in-place alternative to a native
/// confirmationDialog/alert. The first tap arms it and shows a small
/// "Double tap to confirm" caption near the button; a second tap while
/// armed fires `action`; no second tap within the window just fades the
/// caption back out and nothing happens — same safety net as a
/// confirmation alert, without interrupting the screen.
///
/// Each instance owns its own armed state, so dropping one of these into a
/// list row (e.g. a per-exercise remove button) isolates confirmation to
/// that row automatically — no index/ID tracking needed at the call site.
struct TapAgainToConfirmButton<Label: View>: View {
    var confirmWindow: Double = 2.5
    /// Where the caption sits relative to the button — `.top` reads well
    /// for a button in a tightly packed horizontal row (a list row's
    /// remove button), `.leading` for one with room to its side (a
    /// top-bar close button).
    var captionAlignment: Alignment = .top
    var captionAnchor: UnitPoint = .top
    var captionOffset: CGSize = CGSize(width: 0, height: -30)
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isArmed = false
    @State private var armTask: Task<Void, Never>? = nil
    private let impactLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button {
            guard isArmed else {
                impactLight.impactOccurred()
                armTask?.cancel()
                withAnimation(.easeOut(duration: 0.2)) { isArmed = true }
                armTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(confirmWindow))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeIn(duration: 0.2)) { isArmed = false }
                }
                return
            }
            armTask?.cancel()
            isArmed = false
            action()
        } label: {
            label()
        }
        // Exposed as the button's own value (not just the visible caption
        // overlay) so VoiceOver announces the armed state directly, and so
        // it's readable in one query instead of needing a second lookup
        // for the separate caption text — the caption's own discoverability
        // as an independent element isn't reliable across all contexts.
        .accessibilityHint(isArmed ? "Double tap to confirm" : "")
        .accessibilityValue(isArmed ? "Armed, tap again to confirm" : "")
        .overlay(alignment: captionAlignment) {
            if isArmed {
                Text("Double tap to confirm")
                    .font(.luminaCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.75), in: Capsule())
                    .fixedSize()
                    .offset(captionOffset)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: captionAnchor)))
                    .allowsHitTesting(false)
            }
        }
        .onDisappear { armTask?.cancel() }
    }
}
