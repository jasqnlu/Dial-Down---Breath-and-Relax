import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: PlanOption = .annual
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    /// Shows "compare at" strikethrough pricing as a launch promo. Flip to
    /// false once your launch window closes — the real charged price always
    /// comes live from StoreKit regardless of this flag.
    private let isLaunchPeriod = true

    enum PlanOption { case monthly, annual, lifetime }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList
                    planPicker
                    ctaButton

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    footer
                }
                .padding()
            }
            .navigationTitle("Breath Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("Unlock Breath Pro")
                .font(.title2.bold())
            Text("Guided programs, bonus content, and the full experience.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "calendar.badge.clock", text: "30-Day Full Reset guided program")
            featureRow(icon: "sparkles", text: "All future guided programs included")
            featureRow(icon: "heart.fill", text: "Support independent, ad-free development")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
    }

    // MARK: Plan picker

    private var planPicker: some View {
        VStack(spacing: 10) {
            planCard(
                plan: .annual,
                productID: StoreManager.ProductID.annual,
                title: "Annual",
                badge: annualSavingsPercent.map { "Save \($0)%" } ?? "Best Value",
                comparePrice: "39.99",
                period: "/year"
            )
            planCard(
                plan: .monthly,
                productID: StoreManager.ProductID.monthly,
                title: "Monthly",
                badge: nil,
                comparePrice: "5.99",
                period: "/month"
            )
            planCard(
                plan: .lifetime,
                productID: StoreManager.ProductID.lifetime,
                title: "Lifetime",
                badge: "One payment, yours forever",
                comparePrice: "89.99",
                period: nil
            )
        }
    }

    private func planCard(
        plan: PlanOption, productID: String, title: String,
        badge: String?, comparePrice: String, period: String?
    ) -> some View {
        let isSelected = selectedPlan == plan
        let product = store.product(for: productID)

        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.15), in: Capsule())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    if plan != .lifetime {
                        Text("7-day free trial included")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if isLaunchPeriod {
                        Text("$\(comparePrice)\(period ?? "")")
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Text((product?.displayPrice ?? "—") + (period ?? ""))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background(
                isSelected ? Color.accentColor.opacity(0.10) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var annualSavingsPercent: Int? {
        guard
            let monthly = store.product(for: StoreManager.ProductID.monthly)?.price,
            let annual = store.product(for: StoreManager.ProductID.annual)?.price,
            monthly > 0
        else { return nil }
        let yearlyIfPaidMonthly = monthly * 12
        guard yearlyIfPaidMonthly > 0 else { return nil }
        let savings = (1 - (annual / yearlyIfPaidMonthly)) * 100
        return NSDecimalNumber(decimal: savings).intValue
    }

    // MARK: CTA

    private var ctaButton: some View {
        Button(action: purchaseSelected) {
            HStack {
                if isPurchasing {
                    ProgressView().tint(.white)
                }
                Text(selectedPlan == .lifetime ? "Unlock Lifetime" : "Start 7-Day Free Trial")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isPurchasing || selectedProduct == nil)
    }

    private var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly:  return store.product(for: StoreManager.ProductID.monthly)
        case .annual:   return store.product(for: StoreManager.ProductID.annual)
        case .lifetime: return store.product(for: StoreManager.ProductID.lifetime)
        }
    }

    private func purchaseSelected() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                let success = try await store.purchase(product)
                isPurchasing = false
                if success { dismiss() }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.footnote)

            Text("Cancel anytime in Settings. Subscriptions auto-renew until cancelled.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PaywallView()
}
