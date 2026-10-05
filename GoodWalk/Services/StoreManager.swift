import Combine
import Foundation
import StoreKit

/// StoreKit 2. Three products, one entitlement (`isPro`). No receipt server in v1.
@MainActor
final class StoreManager: ObservableObject {
    enum ProductID: String, CaseIterable {
        case yearly = "goodwalk.yearly"
        case monthly = "goodwalk.monthly"
        case lifetime = "goodwalk.lifetime"
    }

    @Published private(set) var products: [Product] = []
    /// Starts from the last answer StoreKit gave, so a subscriber who opens the app from the
    /// widget, Siri or the reminder isn't shown the paywall while entitlements are re-checked.
    @Published private(set) var isPro = false
    /// True once entitlements have been checked this launch. Until then a "no" from `isPro` is
    /// only the cached answer, and the paywall waits for the real one.
    @Published private(set) var hasCheckedEntitlements = false
    /// Apple gives the free trial once per subscription group. Someone who already had it is
    /// charged on day one, so the paywall must not promise it to them.
    @Published private(set) var isEligibleForTrial = true
    @Published private(set) var isLoading = false
    /// True once `load()` has finished at least once, whether or not it found any products.
    @Published private(set) var hasLoaded = false
    @Published var purchaseError: String?

    private static let cachedProKey = "isProCached"
    private var updatesTask: Task<Void, Never>?

    init() {
        isPro = UserDefaults.standard.bool(forKey: Self.cachedProKey)
        // Entitlements need no network and no product list; check them straight away.
        Task { [weak self] in await self?.refreshEntitlements() }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }

    deinit { updatesTask?.cancel() }

    func load() async {
        isLoading = true
        purchaseError = nil
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            let fetched = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            products = fetched.sorted { lhs, rhs in order(of: lhs) < order(of: rhs) }
            // StoreKit returns an empty list, not an error, when the IDs are unknown to the store
            // (no App Store Connect products yet, or no .storekit file attached in the simulator).
            if products.isEmpty {
                purchaseError = "Couldn't load plans. Check your connection."
                Analytics.track(.storeLoadFailed, ["error": "no products returned"])
            }
            // Every subscription here is in one group, so any of them answers for all.
            if let subscription = products.compactMap(\.subscription).first {
                isEligibleForTrial = await subscription.isEligibleForIntroOffer
            }
        } catch {
            purchaseError = "Couldn't load plans. Check your connection."
            Analytics.track(.storeLoadFailed, ["error": String(describing: error)])
        }
        await refreshEntitlements()
    }

    func product(_ id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    /// Returns true when the purchase succeeded and the user is now Pro.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "Purchase couldn't be verified."
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                Analytics.track(hasTrial(product) ? .trialStarted : .paid, ["product": product.id])
                return isPro
            case .userCancelled:
                Analytics.track(.purchaseCancelled, ["product": product.id])
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = "Something went wrong. Try again."
            Analytics.track(.purchaseFailed, ["error": String(describing: error)])
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
        Analytics.track(.restoreTapped, ["isPro": isPro])
    }

    func refreshEntitlements() async {
        defer { hasCheckedEntitlements = true }
        #if DEBUG
        // QA hook: `SIMCTL_CHILD_GOODWALK_FORCE_PRO=1 xcrun simctl launch …` unlocks Pro without a purchase.
        if ProcessInfo.processInfo.environment["GOODWALK_FORCE_PRO"] == "1" {
            isPro = true
            return
        }
        #endif
        var pro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil,
               ProductID(rawValue: transaction.productID) != nil {
                pro = true
            }
        }
        isPro = pro
        UserDefaults.standard.set(pro, forKey: Self.cachedProKey)
    }

    // MARK: - Display helpers

    /// True when buying this product starts a free trial for this person, not merely when the
    /// product has one: the trial is once per Apple ID.
    func hasTrial(_ product: Product) -> Bool {
        isEligibleForTrial && product.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    /// Monthly-equivalent price string for a yearly plan, e.g. "$2.50/mo".
    func perMonthEquivalent(_ product: Product) -> String? {
        guard let sub = product.subscription, sub.subscriptionPeriod.unit == .year else { return nil }
        let monthly = product.price / 12
        return monthly.formatted(product.priceFormatStyle) + "/mo"
    }

    private func order(of product: Product) -> Int {
        switch ProductID(rawValue: product.id) {
        case .yearly: return 0
        case .monthly: return 1
        case .lifetime: return 2
        case .none: return 3
        }
    }
}
