import SwiftUI

/// Collects first + last name after sign-in. Prefilled when Apple/Google (or a
/// pre-existing profile row) supplied a name, but always shown so every account
/// ends up with the same two fields.
struct NameEntryView: View {
    let prefill: PersonName
    let onSubmit: (PersonName) -> Void
    let onSignOut: () -> Void

    @State private var first = ""
    @State private var last = ""
    @FocusState private var focus: Field?

    private enum Field { case first, last }

    private var candidate: PersonName { PersonName(first: first, last: last) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.luminaPrimary)
                    Text("What should we call you?")
                        .font(.luminaTitle)
                        .foregroundStyle(Color.luminaOnSurface)
                        .multilineTextAlignment(.center)
                    Text("Your name shows on your profile and greets you each day.")
                        .font(.luminaSubheadline)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                VStack(spacing: 14) {
                    nameField("First name", text: $first, contentType: .givenName, field: .first)
                        .submitLabel(.next)
                        .onSubmit { focus = .last }
                    nameField("Last name", text: $last, contentType: .familyName, field: .last)
                        .submitLabel(.done)
                        .onSubmit { submitIfValid() }
                }

                Button(action: submitIfValid) {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(LuminaPillButtonStyle())
                .disabled(!candidate.isComplete)

                Button(action: onSignOut) {
                    Text("Not you? Use a different account")
                        .font(.luminaLabel)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Not you? Use a different account")
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.luminaSurface.ignoresSafeArea())
        .onAppear {
            if first.isEmpty && last.isEmpty {
                first = prefill.first
                last = prefill.last
            }
            focus = prefill.first.isEmpty ? .first : nil
        }
    }

    private func nameField(_ label: String, text: Binding<String>,
                           contentType: UITextContentType, field: Field) -> some View {
        TextField(label, text: text)
            .textContentType(contentType)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focus, equals: field)
            .font(.luminaBody)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.luminaContainer, in: RoundedRectangle(cornerRadius: LuminaRadius.tag))
            .accessibilityLabel(label)
    }

    private func submitIfValid() {
        guard candidate.isComplete else { return }
        onSubmit(candidate)
    }
}

#Preview {
    NameEntryView(prefill: PersonName(first: "Ada", last: "Lovelace"),
                  onSubmit: { _ in }, onSignOut: {})
}
