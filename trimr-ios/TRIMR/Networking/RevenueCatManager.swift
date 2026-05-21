import SwiftUI
import RevenueCat

// MARK: - Configuration

enum RevenueCatConfig {
    /// RevenueCat public **App Store** SDK key — used for BOTH DEBUG and RELEASE
    /// (daily-habit pivot, 2026-05-18).
    ///
    /// DEBUG runs on the simulator against the scheme's StoreKit Configuration
    /// file (`Configuration.storekit` — defines `ai.trimr.pro.weekly` /
    /// `.yearly` + the 3-day free trial). RevenueCat fetches the Offering from
    /// its servers with this key and resolves packages against the local
    /// StoreKit config, so the full trial → purchase flow works on the
    /// simulator with no sandbox.
    ///
    /// The old DEBUG **Test Store** key was removed: it serves RevenueCat's
    /// hosted test store, which has no App Store subscription products, so the
    /// weekly/yearly packages never resolved there (→ "That plan isn't
    /// available"). The RC account is verified healthy as of 2026-05-18
    /// (project `proj182095a3`); if this key ever returns "Invalid API Key",
    /// re-copy it from RC dashboard → Project → API keys. See
    /// [[project-ios-revenuecat]].
    static let apiKey = "appl_GhjzqKHitDrYUZMtHWCMyCJxQnQ"

    /// Must EXACTLY match the entitlement identifier in the RevenueCat
    /// dashboard. `ai.trimr.pro.weekly` / `ai.trimr.pro.yearly` are attached to
    /// this entitlement, so an active subscription flips
    /// `RevenueCatManager.isProEntitlementActive`.
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
}
