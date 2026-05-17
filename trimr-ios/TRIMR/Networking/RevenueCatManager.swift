import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Configuration

enum RevenueCatConfig {
    /// RevenueCat public SDK key (iOS, production `appl_…` key).
    static let apiKey = "appl_GhjzqKHitDrYUZMtHWCMyCJxQnQ"

    /// Must EXACTLY match the entitlement identifier configured in the
    /// RevenueCat dashboard (Project → Entitlements). Today the only iOS
    /// products are consumable look packs, which do NOT grant an entitlement,
    /// so this stays inactive until a real "Pro" subscription product is added.
    /// Feature gating still runs off Supabase `profiles` (see ProfileStore) —
    /// this is wired and ready, not yet authoritative.
    static let proEntitlementID = "Hairstyle Try On - Trimr Pro"
}

// MARK: - Manager

/// Thin observable wrapper over RevenueCat's `CustomerInfo`. Kept separate from
/// `StoreKitManager` (which owns the StoreKit 2 → Supabase credit pipeline):
/// this object only reflects RevenueCat's view of the customer for entitlement
/// checks and the Customer Center.
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

// MARK: - Paywall

/// The single place RevenueCat's paywall UI is presented. Both the onboarding
/// paywall step and the in-app "Buy Looks" screen render this so the RC-specific
/// surface lives in one file.
///
/// Purchases run through RevenueCat in **observer mode** (`.myApp`): RC drives
/// the buy/restore UI but does not finish StoreKit transactions. The app-wide
/// `StoreKitManager` listener still redeems each look-pack transaction with the
/// `validate-apple-iap` Supabase function, which remains the source of truth
/// for `profiles.look_credits`. On completion we proactively drain unfinished
/// transactions so credits land without waiting on the background listener.
struct RCPaywallScreen: View {
    var displayCloseButton: Bool = true
    /// Called after a successful purchase (used to advance onboarding / pop).
    var onFinished: () -> Void
    /// Called when the user dismisses the paywall without buying.
    var onDismiss: () -> Void

    @EnvironmentObject private var app: AppState

    var body: some View {
        PaywallView(displayCloseButton: displayCloseButton)
            .onPurchaseCompleted { _ in
                Task {
                    await app.store.processUnfinishedTransactions()
                    await app.profile.load()
                }
                onFinished()
            }
            .onRestoreCompleted { _ in
                // Restoring rarely re-grants consumables, but if an earlier
                // purchase never reached our backend the drain + reload picks
                // it up. Don't auto-advance — let the user proceed themselves.
                Task {
                    await app.store.processUnfinishedTransactions()
                    await app.profile.load()
                }
            }
            .onRequestedDismissal {
                onDismiss()
            }
            .background(Theme.bg.ignoresSafeArea())
    }
}
