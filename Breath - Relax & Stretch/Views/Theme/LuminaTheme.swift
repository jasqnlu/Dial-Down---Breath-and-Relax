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

// MARK: - Border-only drag-to-reorder handle
//
// SwiftUI's List `.onMove` makes a row's entire content the long-press
// drag target, which competes with interactive content inside a
// `.luminaCard` row (duration stepper, remove button) and picks up on
// any incidental long-press. This restricts the drag *pickup* gesture to
// a thin band around the card's rounded-rect edge — via `.contentShape`
// on a stroked outline.
//
// Deliberately NOT built on any system drag session (`.onDrag`/`.onDrop`,
// nor `.draggable`/`.dropDestination`) — both were tried first and, on
// this List, left the source row stuck in its "being dragged" dimmed
// state indefinitely with no reorder ever applying, evidenced by
// file-based logging (the drag itself started fine each time; the
// session's drop/completion side never fired reliably). This is a plain
// `DragGesture` instead: it directly offsets the row under the finger and
// calls `move` the moment the touch crosses into another row's laid-out
// frame — no OS-level drag/drop lifecycle involved, so there's nothing to
// get stuck.

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
    /// Makes this `.luminaCard`-styled row draggable to reorder, but only
    /// from a band around its rounded-rect edge rather than anywhere in
    /// its interior. `move` takes the same `(IndexSet, Int) -> Void`
    /// signature List's own `.onMove` uses, so an existing
    /// `.onMove { array.move(fromOffsets: $0, toOffset: $1) }` closure
    /// can be reused as-is.
    func reorderableByBorder(
        index: Int,
        state: RowReorderState,
        cornerRadius: CGFloat = LuminaRadius.card,
        move: @escaping (IndexSet, Int) -> Void
    ) -> some View {
        modifier(ReorderableByBorder(index: index, state: state, cornerRadius: cornerRadius, move: move))
    }
}

private struct ReorderableByBorder: ViewModifier {
    let index: Int
    @ObservedObject var state: RowReorderState
    var cornerRadius: CGFloat
    let move: (IndexSet, Int) -> Void

    /// Touch band width around the edge — wider than the visible stroke
    /// so the grab target stays comfortable without looking heavy.
    private let bandWidth: CGFloat = 14

    private var isDragging: Bool { state.draggingIndex == index }

    /// How far to visually offset this row while it's the one being
    /// carried — the gap between the finger's current position and this
    /// row's own last-measured center. Recomputed from live layout each
    /// time, so it stays correct across the live reorders below shifting
    /// this row (and its siblings) to new positions mid-drag.
    private var dragOffsetY: CGFloat {
        guard isDragging, let dragLocationY = state.dragLocationY, let frame = state.rowFrames[index] else { return 0 }
        return dragLocationY - frame.midY
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.luminaOutline, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(isDragging ? 0.18 : 0), radius: 12, y: 6)
            .scaleEffect(isDragging ? 1.03 : 1)
            .zIndex(isDragging ? 1 : 0)
            .offset(y: dragOffsetY)
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
            .overlay(
                // Separate layer, its own `.contentShape`: only touches
                // starting within `bandWidth` of the edge can pick this
                // row up.
                Color.clear
                    .contentShape(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: bandWidth))
                    )
                    .gesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .global)
                            .onChanged { value in
                                if state.draggingIndex == nil { state.draggingIndex = index }
                                state.dragLocationY = value.location.y
                                guard let dragging = state.draggingIndex else { return }
                                // Which row's frame currently contains the
                                // finger — that's the live reorder target.
                                if let target = state.rowFrames.first(where: {
                                    value.location.y >= $0.value.minY && value.location.y < $0.value.maxY
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
