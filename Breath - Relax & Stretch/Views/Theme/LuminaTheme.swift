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
    static let luminaPrimary          = Color(UIColor.lumina(light: 0x00685B, dark: 0x6ED8C5))
    static let luminaOnPrimary        = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x00382F))
    static let luminaPrimaryContainer = Color(UIColor.lumina(light: 0x008374, dark: 0x005046))
    static let luminaMintTint         = Color(UIColor.lumina(light: 0xD7F2EA, dark: 0x17332E))
    static let luminaOrange           = Color(UIColor.lumina(light: 0xFF9651, dark: 0x994701))
    static let luminaOnOrange         = Color(UIColor.lumina(light: 0x6F3200, dark: 0xFFDBC8))
    static let luminaBlue             = Color(UIColor.lumina(light: 0x4C6DDD, dark: 0xB6C4FF))
    static let luminaSurface          = Color(UIColor.lumina(light: 0xF8FAFB, dark: 0x0E1413))
    static let luminaCardFill         = Color(UIColor.lumina(light: 0xFFFFFF, dark: 0x1A2120))
    static let luminaContainer        = Color(UIColor.lumina(light: 0xECEEEF, dark: 0x242B2A))
    static let luminaOnSurface        = Color(UIColor.lumina(light: 0x191C1D, dark: 0xEFF1F2))
    static let luminaOnSurfaceVariant = Color(UIColor.lumina(light: 0x3D4946, dark: 0xBCC9C5))
    static let luminaOutline          = Color(UIColor.lumina(light: 0xE1E3E4, dark: 0x2E3835))
    static let luminaGradientStart    = Color(UIColor.lumina(light: 0x4AC4C4, dark: 0x2E7D7D))
    static let luminaGradientEnd      = Color(UIColor.lumina(light: 0x7663F1, dark: 0x4A3D99))
}

// MARK: - Pill button

struct LuminaPillButtonStyle: ButtonStyle {
    enum Kind { case prominent, ghost }
    var kind: Kind = .prominent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.luminaCardTitle)
            .foregroundStyle(kind == .prominent ? Color.luminaOnPrimary : Color.luminaPrimary)
            .padding(.horizontal, 24)
            .frame(minHeight: 48)
            .background(
                kind == .prominent ? Color.luminaPrimary : Color.luminaMintTint,
                in: Capsule()
            )
            .shadow(color: kind == .prominent ? Color.luminaPrimary.opacity(0.25) : .clear,
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
            .background(Color.luminaCardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color(UIColor.lumina(light: 0x0F172A, dark: 0x000000)).opacity(0.05),
                    radius: 10, y: 4)
    }
}

extension View {
    func luminaCard(padding: CGFloat = 16) -> some View {
        modifier(LuminaCard(padding: padding))
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
