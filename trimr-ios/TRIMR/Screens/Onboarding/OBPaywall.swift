import SwiftUI

/// Onboarding paywall step. Presents RevenueCat's dashboard-configured paywall
/// (via `RCPaywallScreen`). Credit granting stays on the StoreKit 2 →
/// `validate-apple-iap` pipeline owned by the app-wide `StoreKitManager`.
struct OBPaywall: View {
    let name: String
    let onClose: () -> Void
    let onPurchased: () -> Void

    var body: some View {
        RCPaywallScreen(
            displayCloseButton: true,
            onFinished: onPurchased,
            onDismiss: onClose
        )
    }
}
