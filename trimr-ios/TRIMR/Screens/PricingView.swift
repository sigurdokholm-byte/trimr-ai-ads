import SwiftUI

/// In-app "Buy Looks" screen. Shown inside `ScreenWrap` (which already provides
/// a back button), so RevenueCat's own close button is hidden here. Returns to
/// the previous screen on purchase or dismissal; credits are reconciled by the
/// app-wide StoreKit listener and reflected via `ProfileStore`.
struct PricingView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        RCPaywallScreen(
            displayCloseButton: false,
            onFinished: { app.pop() },
            onDismiss: { app.pop() }
        )
    }
}
