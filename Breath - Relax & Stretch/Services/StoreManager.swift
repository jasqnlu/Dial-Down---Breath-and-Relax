import StoreKit
import Combine
import os

// MARK: - StoreManager
// StoreKit 2 tip jar. This app has no paid tier: every exercise, content pack
// and guided program is free. Tips are optional, purely to support development,
// and unlock nothing.
//
// Products are defined in Configuration.storekit for local testing (Xcode →
// Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration →
// select the file). Replace with real App Store Connect products before
// shipping — the product IDs below must match exactly, and must be created as
// CONSUMABLE products.
//
// Why tips go through IAP at all: App Review Guideline 3.1.1 requires in-app
// purchase for tips to an individual developer. Linking out to GitHub Sponsors
// or Ko-fi is only permitted for registered non-profits, which this is not.
// The sponsor link lives in the GitHub README instead, not in the app.

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID {
        static let tipSmall = "tip_small"
        static let tipMedium = "tip_medium"
        static let tipLarge = "tip_large"
        /// Ordered smallest → largest; the tip jar renders them in this order.
        static let all = [tipSmall, tipMedium, tipLarge]
    }

    private enum DefaultsKey {
        static let tipCount = "tipjar.tipCount"
        static let recordedTransactionIDs = "tipjar.recordedTransactionIDs"
    }

    @Published private(set) var products: [Product] = []

    /// Number of tips this user has given, persisted locally.
    ///
    /// Consumables do NOT appear in `Transaction.currentEntitlements` — unlike
    /// subscriptions and non-consumables, StoreKit keeps no lasting record of
    /// them for the app to query. So there is nothing to read back on launch
    /// and nothing to "restore"; the only way to remember a tip was given is to
    /// record it ourselves.
    @Published private(set) var tipCount: Int

    /// Whether to show the thank-you state instead of the first-time ask.
    var hasTipped: Bool { tipCount > 0 }

    private let defaults: UserDefaults
    private var recordedTransactionIDs: Set<UInt64>
    private var updatesTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.tipCount = defaults.integer(forKey: DefaultsKey.tipCount)
        let stored = defaults.array(forKey: DefaultsKey.recordedTransactionIDs) as? [NSNumber] ?? []
        self.recordedTransactionIDs = Set(stored.map { $0.uint64Value })

        // Catches transactions that complete outside a `purchase()` call —
        // interrupted purchases, or an Ask to Buy request approved later.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await loadProducts() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func product(for id: String) -> Product? { products.first { $0.id == id } }

    // MARK: - Loading

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            // Preserve the small → large ordering declared in ProductID.all;
            // StoreKit does not guarantee it returns products in request order.
            products = ProductID.all.compactMap { id in loaded.first { $0.id == id } }
        } catch {
            Logger(subsystem: "com.jasonlu.breath", category: "storeKit")
                .warning("Tip product load failed: \(error)")
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

    // MARK: - Transaction handling

    /// Finishes a transaction and counts it, exactly once.
    ///
    /// Both `purchase()` and the `Transaction.updates` listener route through
    /// here, and StoreKit may deliver the same transaction to both. Counting is
    /// therefore keyed on the transaction's own ID rather than on which path
    /// observed it, so a single tip can never increment the count twice.
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        // Consumables must be finished or StoreKit redelivers them forever.
        await transaction.finish()

        guard ProductID.all.contains(transaction.productID),
              !recordedTransactionIDs.contains(transaction.id) else { return }

        recordedTransactionIDs.insert(transaction.id)
        tipCount += 1
        defaults.set(tipCount, forKey: DefaultsKey.tipCount)
        defaults.set(recordedTransactionIDs.map { NSNumber(value: $0) },
                     forKey: DefaultsKey.recordedTransactionIDs)
    }
}
