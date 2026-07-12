import SwiftUI
import StoreKit

// MARK: - ContentPacksView

struct ContentPacksView: View {
    @ObservedObject private var store = StoreManager.shared
    @State private var purchasingID: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            ForEach(ContentPack.all) { pack in
                packSection(pack)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.luminaCaption)
                    .foregroundStyle(.red)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .listRowBackground(Color.luminaCardFill)
        .navigationTitle("Content Packs")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
        .task { await store.loadProducts() }
    }

    private func packSection(_ pack: ContentPack) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: pack.icon)
                    .font(.title2)
                    .foregroundStyle(Color.luminaPrimary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(pack.title).font(.luminaCardTitle).foregroundStyle(Color.luminaOnSurface)
                    Text(pack.summary)
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                    Text("\(pack.exerciseNames.count) exercises included")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)

            if store.owns(pack.id) {
                Label("Unlocked", systemImage: "checkmark.circle.fill")
                    .font(.luminaLabel)
                    .foregroundStyle(.green)
            } else if let product = store.product(for: pack.id) {
                Button {
                    purchase(product)
                } label: {
                    HStack {
                        if purchasingID == pack.id {
                            ProgressView()
                        } else {
                            Text("Buy for \(product.displayPrice)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuminaPillButtonStyle(compact: true))
                .disabled(purchasingID != nil)
            }
        }
    }

    private func purchase(_ product: Product) {
        purchasingID = product.id
        errorMessage = nil
        Task {
            do {
                try await store.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
            purchasingID = nil
        }
    }
}

#Preview {
    NavigationStack {
        ContentPacksView()
    }
}
