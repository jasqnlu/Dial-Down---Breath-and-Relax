import SwiftUI
import StoreKit

// MARK: - TipJarView
// Replaces the old PaywallView. This app has no paid tier — every exercise,
// content pack and guided program is free — so this screen asks for nothing
// and unlocks nothing. It exists only so people who want to support the
// project can.
//
// Deliberately NOT auto-presented anywhere: it's reachable from Profile only.
// The old paywall popped itself after the user's third session, which is
// appropriate for an upsell and obnoxious for a donation request.

struct TipJarView: View {
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var purchasingID: String?
    @State private var errorMessage: String?
    @State private var showThankYou = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    tipOptions

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.luminaCaption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    footer
                }
                .padding()
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .navigationTitle("Support Breath")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await store.loadProducts() }
            .alert("Thank you!", isPresented: $showThankYou) {
                Button("You're welcome") { dismiss() }
            } message: {
                Text("Genuinely — thank you for supporting an independent, open-source project.")
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: store.hasTipped ? "heart.fill" : "heart")
                .font(.system(size: 48))
                .foregroundStyle(Color.luminaPrimary)
                .accessibilityHidden(true)

            Text(store.hasTipped ? "Thanks for your support" : "Breath is free — all of it")
                .font(.luminaTitle)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)

            Text("Every exercise, program and pack is unlocked for everyone, with no ads and no tracking. If you'd like to chip in toward development, you can leave a tip below — it unlocks nothing, and the app works exactly the same either way.")
                .font(.luminaSubheadline)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Tips

    @ViewBuilder
    private var tipOptions: some View {
        if store.products.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 120)
                .accessibilityLabel("Loading tip options")
        } else {
            VStack(spacing: 12) {
                ForEach(store.products, id: \.id) { product in
                    Button {
                        purchase(product)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.displayName)
                                    .font(.luminaCardTitle)
                                Text(product.description)
                                    .font(.luminaCaption)
                                    .foregroundStyle(Color.luminaOnSurfaceVariant)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 12)
                            if purchasingID == product.id {
                                ProgressView()
                            } else {
                                Text(product.displayPrice)
                                    .font(.luminaCardTitle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .buttonStyle(.plain)
                    .luminaCard()
                    .disabled(purchasingID != nil)
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 6) {
            // No "Restore Purchases" button: tips are consumables, and StoreKit
            // keeps no restorable record of them. The button would do nothing.
            Text("Tips are one-time and optional. They don't unlock features, because there aren't any locked features.")
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .multilineTextAlignment(.center)

            if store.hasTipped {
                Text("You've tipped \(store.tipCount) time\(store.tipCount == 1 ? "" : "s"). Thank you.")
                    .font(.luminaCaption)
                    .foregroundStyle(Color.luminaPrimary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Actions

    private func purchase(_ product: Product) {
        purchasingID = product.id
        errorMessage = nil
        Task {
            do {
                if try await store.purchase(product) {
                    showThankYou = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            purchasingID = nil
        }
    }
}

#Preview {
    TipJarView()
}
