import StoreKit
import Combine

// MARK: - StoreManager
// StoreKit 2 entitlement + purchase manager. Products are defined in
// Configuration.storekit for local testing (Xcode → Product → Scheme →
// Edit Scheme → Run → Options → StoreKit Configuration → select the file).
// Replace with real App Store Connect products before shipping — the
// product IDs below must match exactly.

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID {
        static let monthly = "pro_monthly"
        static let annual = "pro_annual"
        static let lifetime = "pro_lifetime"
        static let deskWorkerPack = "pack_deskworker"
        static let athleteRecoveryPack = "pack_athlete_recovery"
        static let all = [monthly, annual, lifetime, deskWorkerPack, athleteRecoveryPack]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await loadProducts()
            await refreshPurchasedProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Entitlements

    var isPro: Bool {
        purchasedProductIDs.contains(ProductID.lifetime)
            || purchasedProductIDs.contains(ProductID.monthly)
            || purchasedProductIDs.contains(ProductID.annual)
    }

    var hasLifetime: Bool { purchasedProductIDs.contains(ProductID.lifetime) }

    func owns(_ productID: String) -> Bool { purchasedProductIDs.contains(productID) }

    func product(for id: String) -> Product? { products.first { $0.id == id } }

    // MARK: - Loading

    func loadProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            #if DEBUG
            print("⚠️ StoreKit product load failed: \(error)")
            #endif
        }
    }

    // MARK: - Purchasing

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            await handle(verification)
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshPurchasedProducts()
    }

    // MARK: - Transaction handling

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshPurchasedProducts()
    }

    private func refreshPurchasedProducts() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.revocationDate == nil else { continue }
            owned.insert(transaction.productID)
        }
        purchasedProductIDs = owned
    }
}
