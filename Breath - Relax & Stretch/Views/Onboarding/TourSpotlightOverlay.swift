import SwiftUI

/// Dims the screen, cuts a spotlight around the current tour step's target,
/// and shows a Lumina-styled tooltip beside it. Renders nothing when the
/// tour isn't active.
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
                dimLayer(cutout: targetRect, size: proxy.size)
                    .allowsHitTesting(step.blocksBackgroundTaps)
                tooltipCard(step: step, targetRect: targetRect, screenSize: proxy.size)
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

    /// A full-screen dim `Path` with the target rect subtracted via an
    /// even-odd fill. Because the cutout is excluded from the path's own
    /// geometry, SwiftUI's default hit-testing lets taps inside it reach the
    /// real view underneath — no extra hit-testing code needed. This is
    /// what makes the interactive body-map steps work.
    private func dimLayer(cutout: CGRect?, size: CGSize) -> some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: size))
            if let cutout {
                let inset = cutout.insetBy(dx: -8, dy: -8)
                path.addRoundedRect(in: inset, cornerSize: CGSize(width: 16, height: 16))
            }
        }
        .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
    }

    private func tooltipCard(step: TourStep, targetRect: CGRect?, screenSize: CGSize) -> some View {
        // No target rect yet (no anchor tagged, no fixedFrame) — center the
        // card on screen rather than anchoring it to nothing.
        let placeBelow = targetRect.map { $0.midY < screenSize.height * 0.55 } ?? true
        let cardWidth = min(screenSize.width - 48, 340)
        // `fixedFrame` targets are small toolbar buttons docked at a screen
        // edge (top-trailing), unlike anchor-based targets which are large
        // content areas with real room around them. The default 110pt
        // clearance is sized for those larger anchors; for a small target
        // this close to the top edge it isn't enough — the card's own
        // (opaque, hit-testing) body ends up overlapping the target rect,
        // swallowing taps meant for the real button underneath. Widen the
        // clearance for this case only; anchor-based steps keep the
        // original 110pt gap untouched.
        let isFixedFrameTarget = step.fixedFrame != nil
        let verticalClearance: CGFloat = isFixedFrameTarget ? 190 : 110

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
        .position(
            x: screenSize.width / 2,
            y: {
                guard let targetRect else { return screenSize.height / 2 }
                return placeBelow
                    ? min(targetRect.maxY + verticalClearance, screenSize.height - 140)
                    : max(targetRect.minY - verticalClearance, 140)
            }()
        )
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
