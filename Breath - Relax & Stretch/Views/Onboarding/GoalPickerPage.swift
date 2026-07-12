import SwiftUI

// MARK: - Goal Picker Page

struct GoalPickerPage: View {
    @Binding var selectedGoals: Set<String>

    private struct Goal: Identifiable {
        let id: String   // used as the key in selectedGoals
        let icon: String
        let label: String
    }

    private let goals: [Goal] = [
        Goal(id: "flexibility",      icon: "figure.flexibility", label: "Flexibility"),
        Goal(id: "stress_relief",    icon: "leaf.fill",          label: "Stress Relief"),
        Goal(id: "pain_relief",      icon: "bandage.fill",       label: "Pain Relief"),
        Goal(id: "better_breathing", icon: "wind",               label: "Better Breathing"),
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                Text("What brings you here?")
                    .font(.luminaDisplay)
                    .foregroundStyle(Color.luminaOnSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("We'll personalise your experience.")
                    .font(.luminaBody)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(goals) { goal in
                        GoalCard(
                            icon: goal.icon,
                            label: goal.label,
                            isSelected: selectedGoals.contains(goal.id)
                        ) {
                            toggleGoal(goal.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)

                Spacer(minLength: 160)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func toggleGoal(_ id: String) {
        if selectedGoals.contains(id) {
            selectedGoals.remove(id)
        } else {
            selectedGoals.insert(id)
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(isSelected ? Color.luminaPrimary : Color.luminaOnSurfaceVariant)

                Text(label)
                    .font(.luminaCardTitle)
                    .foregroundStyle(isSelected ? Color.luminaPrimary : Color.luminaOnSurface)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? Color.luminaMintTint : Color.luminaCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? Color.luminaPrimary : Color.luminaOutline,
                                  lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Goal Picker") {
    StatefulPreviewWrapper(Set<String>()) { binding in
        GoalPickerPage(selectedGoals: binding)
    }
}

// MARK: - Preview Helper

/// Wraps a `@State` binding for preview purposes without needing a parent view.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View { content($value) }
}
