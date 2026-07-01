import SwiftUI

// MARK: - Custom Floating Tab Bar
//
// A floating pill-shaped nav bar that replaces Apple's default tab bar chrome.
// The active tab expands to show its label; inactive tabs show only the icon.
// A matched-geometry capsule slides behind the active item.

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var ns

    private struct TabItem {
        let icon: String
        let activeIcon: String
        let label: String
    }

    private let tabs: [TabItem] = [
        TabItem(icon: "figure.stand",          activeIcon: "figure.stand",           label: "Body"),
        TabItem(icon: "list.bullet",            activeIcon: "list.bullet",             label: "Exercises"),
        TabItem(icon: "wind",                   activeIcon: "wind",                    label: "Breathe"),
        TabItem(icon: "rectangle.stack",        activeIcon: "rectangle.stack.fill",    label: "Routines"),
        TabItem(icon: "person.circle",          activeIcon: "person.circle.fill",      label: "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                tabButton(index: i)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(Color(.systemGray5).opacity(0.8), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.14), radius: 22, x: 0, y: 6)
        }
        .padding(.horizontal, 18)
    }

    private func tabButton(index: Int) -> some View {
        let isActive = selectedTab == index
        let tab = tabs[index]

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                selectedTab = index
            }
        } label: {
            ZStack {
                if isActive {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.12))
                        .matchedGeometryEffect(id: "activePill", in: ns)
                }

                HStack(spacing: isActive ? 5 : 0) {
                    Image(systemName: isActive ? tab.activeIcon : tab.icon)
                        .font(.system(size: 17, weight: isActive ? .semibold : .regular))

                    if isActive {
                        Text(tab.label)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .foregroundStyle(isActive ? Color.accentColor : Color(.systemGray))
                .padding(.vertical, 10)
                .padding(.horizontal, isActive ? 14 : 0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.74), value: selectedTab)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var tab = 0
    VStack {
        Spacer()
        CustomTabBar(selectedTab: $tab)
        Spacer().frame(height: 24)
    }
    .background(Color(.systemGroupedBackground))
}
