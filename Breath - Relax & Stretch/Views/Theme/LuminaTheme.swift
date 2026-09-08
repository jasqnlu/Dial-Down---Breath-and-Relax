import Combine
import SwiftUI

// MARK: - Lumina Mobility design tokens
// Palette from the Stitch redesign (docs/superpowers/specs/
// 2026-07-06-lumina-mobility-restyle-design.md). All colors are dynamic.

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }

    static func lumina(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension Color {
    static let luminaPrimary          = Color(UIColor.lumina(light: 0xB5540A, dark: 0xFFB454))
    static let luminaOnPrimary        = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x2B1400))
    static let luminaMintTint         = Color(UIColor.lumina(light: 0xFFE9D2, dark: 0x33230F))
    static let luminaOrange           = Color(UIColor.lumina(light: 0xFF9651, dark: 0x994701))
    static let luminaOnOrange         = Color(UIColor.lumina(light: 0x6F3200, dark: 0xFFDBC8))
    /// A brighter variant of `luminaOrange`, same hue — used only for the
    /// lit streak flame (TodayView.streakButton), which reads as a small,
    /// glanceable badge rather than a filled container background, so it
    /// wants more punch than `luminaOrange`'s container-friendly tone.
    static let luminaFlameLit         = Color(UIColor.lumina(light: 0xFFAD70, dark: 0xC65C00))
    static let luminaBlue             = Color(UIColor.lumina(light: 0x4C6DDD, dark: 0xB6C4FF))
    static let luminaSurface          = Color(UIColor.lumina(light: 0xF8FAFB, dark: 0x0E1413))
    static let luminaCardFill         = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x1A2120))
    static let luminaContainer        = Color(UIColor.lumina(light: 0xECEEEF, dark: 0x242B2A))
    static let luminaOnSurface        = Color(UIColor.lumina(light: 0x191C1D, dark: 0xEFF1F2))
    static let luminaOnSurfaceVariant = Color(UIColor.lumina(light: 0x3D4946, dark: 0xBCC9C5))
    static let luminaOutline          = Color(UIColor.lumina(light: 0xE1E3E4, dark: 0x2E3835))
    static let luminaGradientStart    = Color(UIColor.lumina(light: 0xFFCB84, dark: 0xC97A2E))
    static let luminaGradientEnd      = Color(UIColor.lumina(light: 0xD9701A, dark: 0x8A4008))
}

// MARK: - Corner radius scale
//
// One source of truth for the handful of intended radii used across cards,
// buttons, and small containers. Values are unchanged from what call sites
// already used — this only replaces the scattered magic numbers.

enum LuminaRadius {
    /// Large surfaces: hero cards, sheets, primary panels.
    static let card: CGFloat = 24
    /// Medium containers: thumbnails, popovers, secondary panels.
    static let panel: CGFloat = 16
    /// Compact controls: selectable buttons/chips, callout boxes.
    static let control: CGFloat = 14
    /// Small inline containers: segmented tabs, icon badges, stepper backgrounds.
    static let chip: CGFloat = 12
    /// Small toolbar/banner containers.
    static let badge: CGFloat = 10
    /// Tiny accents: inline icon tags.
    static let tag: CGFloat = 8
}

// MARK: - Pill button

struct LuminaPillButtonStyle: ButtonStyle {
    enum Kind { case prominent, ghost }
    var kind: Kind = .prominent
    /// Smaller sizing for inline/secondary placements (e.g. a banner action)
    /// that shouldn't compete with a full-width primary CTA.
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .luminaLabel : .luminaCardTitle)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(kind == .prominent ? Color.luminaOnPrimary : Color.luminaPrimary)
            .padding(.horizontal, compact ? 14 : 24)
            .frame(minHeight: compact ? 34 : 48)
            .background(
                kind == .prominent ? Color.luminaPrimary : Color.luminaMintTint,
                in: Capsule()
            )
            .shadow(color: kind == .prominent && !compact ? Color.luminaPrimary.opacity(0.25) : .clear,
                    radius: 10, y: 5)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Card

private struct LuminaCard: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.luminaCardFill, in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous))
            .shadow(color: Color(UIColor.lumina(light: 0x0F172A, dark: 0x000000)).opacity(0.05),
                    radius: 10, y: 4)
    }
}

extension View {
    func luminaCard(padding: CGFloat = 16) -> some View {
        modifier(LuminaCard(padding: padding))
    }
}

// MARK: - Drag-to-reorder handle
//
// Deliberately NOT built on any system drag session (`.onDrag`/`.onDrop`,
// nor `.draggable`/`.dropDestination`) — both were tried first and, on
// this List, left the source row stuck in its "being dragged" dimmed
// state indefinitely with no reorder ever applying, evidenced by
// file-based logging (the drag itself started fine each time; the
// session's drop/completion side never fired reliably). This is a plain
// `DragGesture` instead: it hides the row in place and calls `move` the
// moment the touch crosses into another row's laid-out frame — no OS-level
// drag/drop lifecycle involved, so there's nothing to get stuck.
//
// The dragged row can be picked up from anywhere in its content (not just
// an edge) — a `minimumDistance` of a few points is enough to keep simple
// taps on the row's own buttons (duration stepper, remove) from being
// swallowed as drag starts, since those resolve as taps before any
// meaningful movement occurs.
//
// The floating copy that follows the finger is rendered via
// `ReorderDragOverlay`, placed as a ZStack sibling of the List (see call
// sites) rather than via `.zIndex` on the row itself — `.zIndex` doesn't
// reliably win across List row boundaries, since each row is its own
// UIKit-hosted cell and the List's own cell ordering decides on-screen
// stacking, not SwiftUI's declarative z-order. Rendering the dragged
// row's copy in a sibling overlay above the whole List sidesteps that
// entirely: it's guaranteed to be topmost because nothing in the List can
// draw above its container's overlay.

/// Shared drag state for one reorderable list — one `@StateObject` per
/// screen, referenced (not copied) by every row's `reorderableByBorder`
/// call so they all see the same in-progress drag.
final class RowReorderState: ObservableObject {
    /// Index currently being carried, `nil` when no drag is in progress.
    @Published var draggingIndex: Int?
    /// The dragged finger's current Y position, in `.global` (screen)
    /// coordinates.
    @Published var dragLocationY: CGFloat?
    /// Each row's last-measured on-screen frame (same `.global` space),
    /// keyed by index — used to find which row the finger is currently
    /// over.
    var rowFrames: [Int: CGRect] = [:]
}

extension View {
    /// Makes this `.luminaCard`-styled row draggable to reorder, picked up
    /// from anywhere in its content. `move` takes the same
    /// `(IndexSet, Int) -> Void` signature List's own `.onMove` uses, so
    /// an existing `.onMove { array.move(fromOffsets: $0, toOffset: $1) }`
    /// closure can be reused as-is.
    func reorderableByBorder(
        index: Int,
        state: RowReorderState,
        cornerRadius: CGFloat = LuminaRadius.card,
        move: @escaping (IndexSet, Int) -> Void
    ) -> some View {
        modifier(ReorderableByBorder(index: index, state: state, cornerRadius: cornerRadius, move: move))
    }

}

/// Draws the row currently being dragged (if any) as a floating copy that
/// tracks the touch, always on top of the whole list. `rowContent` builds
/// that row FRESH, live, each time — the same row-building function/
/// closure the caller already uses inside its `List`/`Form` — rather than
/// handing this a pre-captured copy of the row. Two ways of pre-capturing
/// a copy were tried and both failed to render once moved outside the
/// List: an `AnyView` snapshot of the row's `content` rendered as nothing
/// at all (not even its own background/border showed, while a plain
/// `Circle()` in the identical position rendered fine — isolating the
/// failure to the relocated view itself), and `ImageRenderer(content:)`
/// consistently returned `nil` for `.uiImage`. A fresh live call sidesteps
/// both: it's just the same view-building code invoked again, in a place
/// that already has full access to whatever environment it needs, with no
/// view identity or snapshot to carry across.
///
/// Place this as a ZStack SIBLING of the `List`/`Form` — not a
/// `.overlay()` modifier attached to it — sharing the same
/// `RowReorderState` passed to each row's `reorderableByBorder`.
/// `.overlay()` on the List itself doesn't work: List hosts each row in
/// its own UIKit-backed cell, and those cells composite above a same-list
/// `.overlay()` regardless of the overlay's own z-order, so content
/// rendered there stays invisible behind the row cells (confirmed via
/// logging — the view's `body` was evaluating with correct content/
/// position every time, it just never appeared on screen). A ZStack
/// sibling is a wholly separate layer stacked on top, outside the List's
/// own compositing.
///
/// This is also why it's a dedicated `View` struct rather than an inline
/// closure built inside a `View` extension function: only a real `View`
/// conformer's own `@ObservedObject` subscribes to `state`'s `@Published`
/// changes — a `GeometryReader { }` closure captured directly inside an
/// extension function's `some View` never re-evaluates when `state`
/// changes elsewhere, since nothing established that subscription.
struct ReorderDragOverlay<RowContent: View>: View {
    @ObservedObject var state: RowReorderState
    @ViewBuilder var rowContent: (Int) -> RowContent

    var body: some View {
        GeometryReader { proxy in
            if let index = state.draggingIndex,
               let frame = state.rowFrames[index] {
                let origin = proxy.frame(in: .global).origin
                rowContent(index)
                    .frame(width: frame.width, height: frame.height)
                    .shadow(color: Color.black.opacity(0.25), radius: 16, y: 8)
                    .scaleEffect(1.04)
                    .position(
                        x: frame.midX - origin.x,
                        y: (state.dragLocationY ?? frame.midY) - origin.y
                    )
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ReorderableByBorder: ViewModifier {
    let index: Int
    @ObservedObject var state: RowReorderState
    var cornerRadius: CGFloat
    let move: (IndexSet, Int) -> Void

    /// How long a touch must hold still before it's treated as a
    /// reorder-drag rather than the start of a scroll.
    private let longPressMinimumDuration: Double = 0.5

    private var isDragging: Bool { state.draggingIndex == index }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.luminaOutline, lineWidth: 1.5)
            )
            // The row itself goes invisible (not removed — its layout
            // space still reserves the slot) while its floating copy
            // (`reorderDragOverlay`) does the visible following-the-
            // finger. Opacity, unlike `.hidden()`, doesn't interrupt the
            // gesture already recognized on this view.
            .opacity(isDragging ? 0 : 1)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75), value: state.draggingIndex)
            .onGeometryChange(for: CGRect.self) { proxy in
                // `.global`, not a named space anchored to the List —
                // named coordinate spaces (tried both the classic
                // `CoordinateSpace.named` and the newer
                // `CoordinateSpaceProtocol` form) never lined up with
                // `DragGesture`'s own `value.location` here: row frames
                // measured in "reorderList" landed in the hundreds while
                // the gesture reported near-zero for the same on-screen
                // point, indicating the named space doesn't bridge
                // correctly across List's per-row hosting boundary on
                // this SDK. `.global` has no such ambiguity — both this
                // and the gesture below read the same screen-relative
                // coordinates unconditionally.
                proxy.frame(in: .global)
            } action: { newFrame in
                state.rowFrames[index] = newFrame
            }
            .contentShape(Rectangle())
            // A brief hold, not an immediate drag: since the row is now
            // pickup-able from anywhere in its content (not just an
            // edge), a plain DragGesture here would compete with the
            // List's own scroll gesture on every scroll swipe. Requiring
            // `longPressMinimumDuration` of stillness first means a scroll
            // (touch moving right away) never satisfies the long press,
            // so the touch falls through to the List's scroll gesture
            // untouched — reordering only engages once the hold succeeds.
            .gesture(
                LongPressGesture(minimumDuration: longPressMinimumDuration)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                    .onChanged { value in
                        // `.second(true, let drag)` is the only state that
                        // means "the hold succeeded and a drag is now in
                        // progress" — `.first` is the hold still pending,
                        // and `drag` is nil for the single instant the
                        // gesture transitions before the first drag value
                        // arrives.
                        guard case .second(true, let drag) = value, let drag else { return }
                        if state.draggingIndex == nil {
                            state.draggingIndex = index
                        }
                        state.dragLocationY = drag.location.y
                        guard let dragging = state.draggingIndex else { return }
                        // Which row's frame currently contains the
                        // finger — that's the live reorder target.
                        if let target = state.rowFrames.first(where: {
                            drag.location.y >= $0.value.minY && drag.location.y < $0.value.maxY
                        })?.key, target != dragging {
                            move(IndexSet(integer: dragging), target > dragging ? target + 1 : target)
                            state.draggingIndex = target
                        }
                    }
                    .onEnded { _ in
                        state.draggingIndex = nil
                        state.dragLocationY = nil
                    }
            )
    }
}

// MARK: - Filter chip

struct LuminaChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.luminaLabel)
                .foregroundStyle(isSelected ? Color.luminaOnOrange : Color.luminaOnSurfaceVariant)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.luminaOrange : Color.luminaContainer, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
