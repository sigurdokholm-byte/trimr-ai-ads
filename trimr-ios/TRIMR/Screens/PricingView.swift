import SwiftUI
import StoreKit

/// In-app "Buy Looks" screen — the app's own custom StoreKit paywall (NOT
/// RevenueCat's `PaywallView`). Shown inside `ScreenWrap`, which already
/// provides the back button + title, so there is no close button here.
/// Purchases run through the app-wide `StoreKitManager` (`app.store`) →
/// `validate-apple-iap` → `profiles.look_credits`; RevenueCat stays in
/// observer mode for tracking only and does not drive this UI.
struct PricingView: View {
    @EnvironmentObject private var app: AppState
    @State private var selected: StoreKitManager.ProductID = .looks10
    @State private var loaded: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false

    private var store: StoreKitManager { app.store }

    private struct Pack {
        let id: StoreKitManager.ProductID
        let count: Int
        let badge: String?
        let badgeColor: Color
    }
    private let packs: [Pack] = [
        .init(id: .looks3,  count: 3,  badge: nil,             badgeColor: .clear),
        .init(id: .looks10, count: 10, badge: "MOST POPULAR",  badgeColor: Theme.gold),
        .init(id: .looks30, count: 30, badge: "BEST VALUE",    badgeColor: Color(hex: 0xC87080)),
    ]

    private let features = [
        "10+ Ultra-realistic Hairstyle Results",
        "Transform Your Look with Any Hairstyle",
        "All Hairstyles & Colors Unlocked",
        "Try Multiple Looks Before Your Salon Visit",
        "Save & Share to Get Feedback",
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Text("Unlock Your Looks")
                            .font(TFont.display(32))
                            .tracking(-0.6)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.text)
                        Text("Ultra-realistic try-ons matched to your face shape.\nSee your best haircut before you commit.")
                            .font(TFont.body(13.5))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(features, id: \.self) { line in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.gold)
                                Text(line)
                                    .font(TFont.body(13.5))
                                    .foregroundStyle(Theme.text)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                    HStack(spacing: 10) {
                        ForEach(packs, id: \.id) { pack in
                            packCard(pack: pack)
                        }
                    }

                    Text("Credits never expire. Use them whenever you want.")
                        .font(TFont.body(11.5))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 10) {
                Button {
                    Task { await purchase() }
                } label: {
                    HStack {
                        if store.isPurchasing { ProgressView().tint(Color(hex: 0x0A0804)) }
                        Text(store.isPurchasing ? "Processing…" : "Get Credits Now")
                            .font(TFont.body(16, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0A0804))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow).clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(store.isPurchasing || !loaded)

                HStack(spacing: 18) {
                    Button("Terms") { showTerms = true }
                    Text("·").foregroundStyle(Theme.muted.opacity(0.5))
                    Button("Privacy Policy") { showPrivacy = true }
                    Text("·").foregroundStyle(Theme.muted.opacity(0.5))
                    Button("Restore") { Task { await store.restorePurchases() } }
                }
                .font(TFont.body(11.5))
                .foregroundStyle(Theme.muted)

                if let err = store.purchaseError {
                    Text(err)
                        .font(TFont.body(11))
                        .foregroundStyle(Theme.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                if let msg = store.restoreMessage {
                    Text(msg)
                        .font(TFont.body(11))
                        .foregroundStyle(Theme.gold)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            await store.loadProducts()
            loaded = true
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsOfServiceView()
                    .navigationTitle("Terms of Service")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTerms = false }
                                .foregroundStyle(Theme.gold)
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                PrivacyPolicyView()
                    .navigationTitle("Privacy Policy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showPrivacy = false }
                                .foregroundStyle(Theme.gold)
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func packCard(pack: Pack) -> some View {
        let product = store.product(for: pack.id)
        let isSelected = selected == pack.id
        return VStack(spacing: 0) {
            ZStack {
                if let badge = pack.badge {
                    Text(badge)
                        .font(TFont.mono(9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Color(hex: 0x0A0804))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(pack.badgeColor)
                        .clipShape(Capsule())
                } else {
                    Color.clear
                }
            }
            .frame(height: 22)
            .padding(.bottom, 6)

            Button {
                selected = pack.id
            } label: {
                VStack(spacing: 4) {
                    Text("\(pack.count)")
                        .font(TFont.display(34)).tracking(-0.6)
                        .foregroundStyle(Theme.text)
                    Text("LOOKS")
                        .font(TFont.mono(9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.muted)
                    Spacer().frame(height: 8)
                    Text(product?.displayPrice ?? "—")
                        .font(TFont.display(15)).tracking(-0.2)
                        .foregroundStyle(Theme.text)
                    Text("one-time")
                        .font(TFont.body(10))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity).frame(height: 138)
                .background(isSelected ? Theme.gold.opacity(0.08) : Theme.card2)
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Theme.gold : Color.white.opacity(0.06),
                            lineWidth: isSelected ? 2 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func purchase() async {
        guard let product = store.product(for: selected) else { return }
        // Pop only when StoreKit AND the server both confirmed the purchase.
        // `purchase()` returns false for user-cancel, pending, and errors — a
        // cancelled purchase sets no `purchaseError`, so checking that flag
        // would dismiss the screen as if the credits had landed.
        let didPurchase = await store.purchase(product)
        if didPurchase {
            await app.profile.load()
            app.pop()
        }
    }
}
