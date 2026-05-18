import SwiftUI
import RevenueCat

// MARK: - Configuration

enum RevenueCatConfig {
    /// RevenueCat public SDK keys.
    ///
    /// DEBUG builds use the **Test Store** key: it works on the simulator with
    /// the local `Configuration.storekit` file with no App Store Connect setup,
    /// so the paywall + purchase flow can be exercised end-to-end during
    /// development. RELEASE builds use the production **App Store** (`appl_…`)
    /// key — RevenueCat rejects (and App Review flags) a Test Store key in
    /// production, so the two must never be swapped.
    ///
    /// ⚠️ The App Store app in the RevenueCat dashboard must be fully
    /// provisioned (bundle id `com.trimrai.app` + App Store Connect in-app
    /// purchase key) before the `appl_…` key returns anything but
    /// "Invalid API Key". See [[project-ios-revenuecat]].
    #if DEBUG
    static let apiKey = "test_irpwYLREFODNfzhwHJUPZikppsA"
    #else
    static let apiKey = "appl_GhjzqKHitDrYUZMtHWCMyCJxQnQ"
    #endif

    /// Must EXACTLY match the entitlement identifier configured in the
    /// RevenueCat dashboard (Project → Entitlements). Today the only iOS
    /// products are consumable look packs, which do NOT grant an entitlement,
    /// so this stays inactive until a real "Pro" subscription product is added.
    /// Feature gating still runs off Supabase `profiles` (see ProfileStore) —
    /// this is wired and ready, not yet authoritative.
    static let proEntitlementID = "Hairstyle Try On - Trimr Pro"
}

// MARK: - Manager

/// Thin observable wrapper over RevenueCat's `CustomerInfo`. RevenueCat runs
/// in **observer mode** purely for revenue/customer tracking — it does NOT
/// render or drive any paywall. The app's own custom StoreKit paywalls
/// (`OBPaywall`, `PricingView`) + `StoreKitManager` own the purchase/credit
/// pipeline. This object only reflects RevenueCat's view of the customer for
/// entitlement checks.
@MainActor
final class RevenueCatManager: ObservableObject {
    @Published private(set) var customerInfo: CustomerInfo?

    // MARK: RC-authoritative subscription state (daily-habit pivot, 2026-05-18)
    // Additive: nothing in the funnel calls these yet (P1b cutover wires them
    // once the RC account/keys are fixed — see [[project-ios-revenuecat]]).

    enum PaywallState { case loading, ready, unavailable }

    @Published private(set) var offering: Offering?
    @Published private(set) var paywallState: PaywallState = .loading
    @Published private(set) var isPurchasing = false
    @Published var purchaseError: String?

    private var streamTask: Task<Void, Never>?

    init() {
        // Live updates: fires on purchase, restore, renewal, expiration, and
        // after `Purchases.logIn`.
        streamTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.customerInfo = info
            }
        }
        Task { await refresh() }
    }

    deinit { streamTask?.cancel() }

    /// True only when the dashboard-configured Pro entitlement is active.
    /// Not used for gating yet (consumable packs don't grant it) — exposed so a
    /// future subscription can flip features on without re-plumbing.
    var isProEntitlementActive: Bool {
        customerInfo?.entitlements[RevenueCatConfig.proEntitlementID]?.isActive == true
    }

    func refresh() async {
        customerInfo = try? await Purchases.shared.customerInfo()
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
            return true
        } catch {
            print("[RevenueCat] restore failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - RC-authoritative subscription flow

    /// Loads the current Offering. `paywallState` drives a graceful fallback so
    /// a broken RC account (Error 23) can't dead-end onboarding — the UI shows
    /// a non-blocking "store unavailable" instead of RC's raw error.
    func loadOffering() async {
        paywallState = .loading
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current, !current.availablePackages.isEmpty {
                offering = current
                paywallState = .ready
            } else {
                offering = nil
                paywallState = .unavailable
            }
        } catch {
            print("[RevenueCat] offerings failed: \(error.localizedDescription)")
            offering = nil
            paywallState = .unavailable
        }
    }

    /// First package whose StoreKit product id matches, regardless of how the
    /// RC dashboard names its package identifiers.
    func package(productId: String) -> Package? {
        offering?.availablePackages.first { $0.storeProduct.productIdentifier == productId }
    }

    var weeklyPackage: Package? {
        offering?.weekly ?? package(productId: "ai.trimr.pro.weekly")
    }

    var yearlyPackage: Package? {
        offering?.annual ?? package(productId: "ai.trimr.pro.yearly")
    }

    /// Purchases a package via RevenueCat (RC-authoritative). Returns true only
    /// when the Pro entitlement is active afterwards. The `revenuecat-webhook`
    /// edge fn mirrors the entitlement into `profiles.subscription_tier` so
    /// server-side gating stays valid; callers should also refresh the profile.
    @discardableResult
    func purchase(_ package: Package) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        purchaseError = nil
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return false }
            customerInfo = result.customerInfo
            return result.customerInfo.entitlements[RevenueCatConfig.proEntitlementID]?.isActive == true
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Plan-based surface (keeps RevenueCat types out of the view layer)

    enum Plan { case weekly, yearly }

    private func packageFor(_ plan: Plan) -> Package? {
        switch plan {
        case .weekly: return weeklyPackage
        case .yearly: return yearlyPackage
        }
    }

    /// Localized App Store price string for the plan, e.g. "$6.99" — nil until
    /// the offering has loaded.
    func priceString(for plan: Plan) -> String? {
        packageFor(plan)?.storeProduct.localizedPriceString
    }

    @discardableResult
    func purchase(plan: Plan) async -> Bool {
        guard let pkg = packageFor(plan) else {
            purchaseError = "That plan isn't available right now. Please try again."
            return false
        }
        return await purchase(pkg)
    }
}
