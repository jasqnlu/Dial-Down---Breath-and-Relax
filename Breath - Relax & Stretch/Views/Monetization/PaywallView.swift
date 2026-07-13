import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: PlanOption = .annual
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    @State private var legalDocument: LegalDocument?

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
                            .font(.luminaCaption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    footer
                }
                .padding()
            }
            .background(Color.luminaSurface.ignoresSafeArea())
            .navigationTitle("Breath Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
            .alert("Restore Failed", isPresented: .constant(store.restoreError != nil)) {
                Button("OK") { store.restoreError = nil }
            } message: {
                Text(store.restoreError ?? "")
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 48))
                .foregroundStyle(Color.luminaPrimary)
            Text("Unlock Breath Pro")
                .font(.luminaTitle)
                .foregroundStyle(Color.luminaOnSurface)
            Text("Guided programs, bonus content, and the full experience.")
                .font(.luminaSubheadline)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
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
        .luminaCard()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.luminaPrimary)
                .frame(width: 24)
            Text(text)
                .font(.luminaSubheadline)
                .foregroundStyle(Color.luminaOnSurface)
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
                period: "/year"
            )
            planCard(
                plan: .monthly,
                productID: StoreManager.ProductID.monthly,
                title: "Monthly",
                badge: nil,
                period: "/month"
            )
            planCard(
                plan: .lifetime,
                productID: StoreManager.ProductID.lifetime,
                title: "Lifetime",
                badge: "One payment, yours forever",
                period: nil
            )
        }
    }

    private func planCard(
        plan: PlanOption, productID: String, title: String,
        badge: String?, period: String?
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
                            .font(.luminaCardTitle)
                            .foregroundStyle(Color.luminaOnSurface)
                        if let badge {
                            Text(badge)
                                .font(.luminaCaption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.luminaOrange, in: Capsule())
                                .foregroundStyle(Color.luminaOnOrange)
                        }
                    }
                    if let trialText = Self.trialDescription(for: product) {
                        Text("\(trialText) included")
                            .font(.luminaCaption)
                            .foregroundStyle(Color.luminaOnSurfaceVariant)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text((product?.displayPrice ?? "—") + (period ?? ""))
                        .font(.luminaCardTitle)
                        .foregroundStyle(Color.luminaOnSurface)
                }
            }
            .padding()
            .background(
                isSelected ? Color.luminaMintTint : Color.luminaCardFill,
                in: RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? Color.luminaPrimary : Color.luminaOutline,
                                  lineWidth: isSelected ? 2 : 1)
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

    /// Builds a free-trial description directly from the product's StoreKit
    /// introductory offer, e.g. "7-Day Free Trial". Returns nil when the
    /// product has no introductory offer or the offer isn't a free trial —
    /// no copy should be shown in that case.
    private static func trialDescription(for product: Product?) -> String? {
        guard let offer = product?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial
        else { return nil }

        let count = offer.period.value
        let unit: String
        switch offer.period.unit {
        case .day:   unit = "Day"
        case .week:  unit = "Week"
        case .month: unit = "Month"
        case .year:  unit = "Year"
        @unknown default: unit = "Day"
        }
        return "\(count)-\(unit) Free Trial"
    }

    // MARK: CTA

    private var ctaButton: some View {
        Button(action: purchaseSelected) {
            HStack {
                if isPurchasing {
                    ProgressView().tint(Color.luminaOnPrimary)
                }
                Text(ctaTitle)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LuminaPillButtonStyle())
        .disabled(isPurchasing || selectedProduct == nil)
    }

    private var ctaTitle: String {
        if selectedPlan == .lifetime { return "Unlock Lifetime" }
        if let trialText = Self.trialDescription(for: selectedProduct) {
            return "Start \(trialText)"
        }
        return "Subscribe"
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
            .font(.luminaLabel)
            .foregroundStyle(Color.luminaPrimary)

            Text("Cancel anytime in Settings. Subscriptions auto-renew until cancelled.")
                .font(.luminaCaption)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Button("Terms of Use") { legalDocument = .termsOfUse }
                Text("·").foregroundStyle(Color.luminaOnSurfaceVariant)
                Button("Privacy Policy") { legalDocument = .privacyPolicy }
            }
            .font(.luminaCaption)
            .foregroundStyle(Color.luminaPrimary)
        }
        .sheet(item: $legalDocument) { document in
            LegalDocumentView(document: document)
        }
    }
}

#Preview {
    PaywallView()
}
