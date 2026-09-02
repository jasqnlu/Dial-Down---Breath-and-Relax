import SwiftUI

/// Highlights the current tour step's target with a glowing outline and
/// shows a Lumina-styled tooltip pinned near the bottom of the screen.
/// Nothing dims and nothing blocks taps — the real app stays fully visible
/// and fully interactive underneath, including the tab bar itself. Renders
/// nothing when the tour isn't active.
///
/// `anchors`/`proxy` are supplied by the caller (`HomeView`) via
/// `.overlayPreferenceValue` attached to its OUTER ZStack, since
/// `.overlayPreferenceValue`/`.onPreferenceChange` can only observe
/// preference values bubbling up from a view's own subtree — this view
/// itself has no subtree of `.tourAnchor`-tagged content to observe.
struct TourSpotlightOverlay: View {
    @EnvironmentObject private var coordinator: TourCoordinator
    let anchors: [String: Anchor<CGRect>]
    let proxy: GeometryProxy

    var body: some View {
        if coordinator.isActive, let step = coordinator.currentStep {
            let targetRect = resolvedRect(for: step, anchors: anchors, proxy: proxy)
            ZStack {
                if let targetRect {
                    highlightRing(around: targetRect)
                }
                tooltipCard(step: step, targetRect: targetRect, anchors: anchors, proxy: proxy)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: step.id)
        }
    }

    private func resolvedRect(for step: TourStep, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) -> CGRect? {
        if let fixedFrame = step.fixedFrame {
            return fixedFrame(proxy)
        }
        guard let anchor = anchors[step.id] else { return nil }
        return proxy[anchor]
    }

    /// A glowing accent-colored outline around the current target — no fill,
    /// so it never dims or hit-tests the real content underneath. This is
    /// the tour's only visual callout now that the screen always stays lit
    /// and fully tappable.
    private func highlightRing(around rect: CGRect) -> some View {
        let inset = rect.insetBy(dx: -8, dy: -8)
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.luminaPrimary, lineWidth: 3)
            .shadow(color: Color.luminaPrimary.opacity(0.6), radius: 10)
            .frame(width: inset.width, height: inset.height)
            .position(x: inset.midX, y: inset.midY)
            .allowsHitTesting(false)
    }

    private func tooltipCard(step: TourStep, targetRect: CGRect?, anchors: [String: Anchor<CGRect>], proxy: GeometryProxy) -> some View {
        let screenSize = proxy.size
        let cardWidth = min(screenSize.width - 48, 340)

        // Always sit just above the real tab bar, whatever its anchor
        // reports — that's the one thing on every screen worth staying
        // clear of by default. If that hasn't resolved yet, fall back to a
        // reasonable guess rather than pinning to the very bottom edge.
        let tabBarTop = anchors["chrome.tabBar"].map { screenSize.height - proxy[$0].minY }
            ?? 90
        var bottomInset = tabBarTop + 16

        // A small, precisely-tappable target near the bottom — like the
        // body map's floating "Find Stretches" action bar — needs the card
        // pushed clear of its own TOP edge, not just the tab bar's:
        // otherwise the card's height (which varies with message length)
        // can grow up over it. Comparing against the target's bottom edge
        // alone isn't enough — a short target sitting well above the tab
        // bar can still end up under a tall card growing upward from the
        // pinned baseline.
        //
        // Large targets (the body scene itself, which spans nearly the
        // whole screen) are deliberately exempt: there's no way to clear a
        // target that big, and tapping it works from anywhere on it, so
        // the card sitting low and covering its bottom edge is fine.
        if let targetRect, targetRect.height < 200 {
            bottomInset = max(bottomInset, screenSize.height - targetRect.minY + 16)
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(step.title)
                    .font(.luminaTitle)
                    .foregroundStyle(Color.luminaOnSurface)
                Spacer()
                Button {
                    coordinator.finish()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                .accessibilityLabel("Exit tour")
            }

            Text(step.message)
                .font(.luminaBody)
                .foregroundStyle(Color.luminaOnSurfaceVariant)

            HStack(spacing: 6) {
                ForEach(0..<coordinator.totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == coordinator.currentStepIndex ? Color.luminaPrimary : Color.luminaOutline)
                        .frame(width: index == coordinator.currentStepIndex ? 16 : 6, height: 6)
                }
            }
            .accessibilityLabel("Step \(coordinator.stepNumber) of \(coordinator.totalSteps)")

            HStack(spacing: 10) {
                if !coordinator.isFirstStepInSection {
                    Button("Back") { coordinator.back() }
                        .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))
                }

                Button("Skip") { coordinator.skipToNextSection() }
                    .buttonStyle(LuminaPillButtonStyle(kind: .ghost, compact: true))

                Spacer(minLength: 0)

                if !step.isInteractive {
                    Button(coordinator.stepNumber == coordinator.totalSteps ? "Done" : "Next") {
                        coordinator.advance()
                    }
                    .buttonStyle(LuminaPillButtonStyle(compact: true))
                }
            }
        }
        .padding(20)
        .frame(width: cardWidth, alignment: .leading)
        .background(Color.luminaCardFill, in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, bottomInset)
    }
}

// MARK: - Preview

#Preview {
    let coordinator = TourCoordinator()
    coordinator.restart()
    return GeometryReader { proxy in
        ZStack {
            Color.luminaSurface.ignoresSafeArea()
            TourSpotlightOverlay(anchors: [:], proxy: proxy)
        }
    }
    .environmentObject(coordinator)
}
