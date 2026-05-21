import Foundation
import StoreKit
import Supabase

/// StoreKit 2 wrapper. Exposes the product catalogue, handles purchases,
/// and calls the `validate-apple-iap` edge function to credit the user's profile.
@MainActor
final class StoreKitManager: ObservableObject {
    // Must match App Store Connect product IDs.
    enum ProductID: String, CaseIterable {
        case looks3      = "ai.trimr.looks.3"
        case looks10     = "ai.trimr.looks.10"
        case looks30     = "ai.trimr.looks.30"

        var looksGranted: Int {
            switch self {
            case .looks3:  return 3
            case .looks10: return 10
            case .looks30: return 30
            }
        }
    }

    @Published private(set) var products: [StoreKit.Product] = []
    @Published private(set) var isPurchasing: Bool = false
    @Published var purchaseError: String?
    @Published var restoreMessage: String?
    /// Surfaced inline on the paywall when `loadProducts()` returns nothing
    /// or throws. Kept separate from `purchaseError` so the alert (bound to
    /// purchaseError) doesn't pop on first launch — the inline caption is enough.
    @Published var loadFailureNote: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
    }

    deinit { transactionListener?.cancel() }

    func product(for id: ProductID) -> StoreKit.Product? {
        products.first(where: { $0.id == id.rawValue })
    }

    // MARK: - Load

    func loadProducts() async {
        loadFailureNote = nil
        let all = ProductID.allCases.map(\.rawValue)
        do {
            let loaded = try await StoreKit.Product.products(for: all)
            products = loaded.sorted { lhs, rhs in
                let li = ProductID.allCases.firstIndex(where: { $0.rawValue == lhs.id }) ?? 0
                let ri = ProductID.allCases.firstIndex(where: { $0.rawValue == rhs.id }) ?? 0
                return li < ri
            }
            // Logs left unguarded so TestFlight/Release installs surface this in
            // Console.app — App Review 2.1(b) keeps biting us when products fail
            // to load and we have no visibility into why.
            print("[StoreKit] Requested \(all.count) products, App Store returned \(loaded.count): \(loaded.map(\.id))")
            if loaded.isEmpty {
                let ids = all.joined(separator: ", ")
                loadFailureNote = "No offers returned by the App Store for: \(ids). Usually means the IAPs aren't Ready to Submit, the Paid Apps Agreement isn't active, or the network is offline."
                print("[StoreKit] Empty response. Check App Store Connect: IAP status (Ready to Submit), Paid Apps Agreement (Active), and that IAPs are attached to the build's version.")
            }
        } catch {
            loadFailureNote = "Couldn't reach the App Store: \(error.localizedDescription)"
            print("[StoreKit] loadProducts failed for \(all): \(error)")
        }
    }

    // MARK: - Purchase

    /// Returns `true` only when the user actually completed and paid for the
    /// purchase AND the server credited them. Callers must advance the
    /// user past the paywall only on `true` — cancel, pending, and errors
    /// must all leave them on the paywall. The result is intentionally NOT
    /// `@discardableResult`: a cancel returns `false` without setting
    /// `purchaseError`, so any caller that drops this value and infers
    /// success some other way will let cancellers through for free.
    func purchase(_ product: StoreKit.Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        // Clear stale errors from previous attempts so the alert from an
        // earlier failure doesn't linger over a fresh purchase sheet.
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                // Only finish the StoreKit transaction once the server has
                // accepted it. If `redeem` throws (network drop, auth failure,
                // server error), leave the transaction in StoreKit's
                // `Transaction.unfinished` queue — the listener replays it on
                // next launch with whichever session is current at that point.
                try await redeem(tx, productId: product.id)
                await tx.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                purchaseError = "Unexpected response from the App Store. Please try again."
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        purchaseError = nil
        restoreMessage = nil
        do {
            try await AppStore.sync()
            var restored = 0
            for await result in StoreKit.Transaction.currentEntitlements {
                guard let tx = try? checkVerified(result) else { continue }
                // Best-effort: a single bad redeem shouldn't abort the loop.
                // The dedup UNIQUE on apple_iap_transactions.transaction_id
                // makes already-credited rows return success without
                // double-crediting.
                if (try? await redeem(tx, productId: tx.productID)) != nil {
                    restored += 1
                }
            }
            restoreMessage = restored > 0
                ? "Purchases restored."
                : "No previous purchases found on this Apple ID."
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// Drain every transaction the App Store still considers unfinished and
    /// redeem each with the backend. In RevenueCat observer mode RC does not
    /// finish transactions, so a consumable just bought through RC's paywall
    /// sits in `Transaction.unfinished` until we redeem + finish it here.
    /// Called right after a paywall purchase so credits land immediately
    /// instead of waiting on the background listener's next tick. Idempotent:
    /// the UNIQUE on `apple_iap_transactions.transaction_id` dedups, so a
    /// transaction the listener already handled is a harmless no-op.
    func processUnfinishedTransactions() async {
        for await result in StoreKit.Transaction.unfinished {
            guard let tx = try? checkVerified(result) else { continue }
            do {
                try await redeem(tx, productId: tx.productID)
                await tx.finish()
            } catch {
                print("[StoreKit] processUnfinished redeem failed; listener will retry: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Server validation

    private func redeem(_ tx: StoreKit.Transaction, productId: String) async throws {
        // Make sure we have a valid JWT before POSTing — if the session expired
        // or never existed, this auto-refreshes (or throws so the caller can
        // leave the StoreKit transaction unfinished and retry on next launch).
        _ = try await Supa.client.auth.session
        let jws = tx.jsonRepresentation.base64EncodedString()
        let body = AppleIAPValidateRequest(signedTransaction: jws, productId: productId)
        // Race the call against a 20s timeout so a cold edge function or
        // network drop can never leave the purchase spinner spinning forever.
        // On timeout the StoreKit transaction stays unfinished and the
        // background listener replays it on next launch.
        let invokeTask = Task<Void, Error> {
            let _: AppleIAPValidateResponse = try await Supa.client.functions
                .invoke("validate-apple-iap", options: .init(body: body))
        }
        let timeoutTask = Task<Void, Error> {
            try await Task.sleep(nanoseconds: 20_000_000_000)
            invokeTask.cancel()
        }
        do {
            try await invokeTask.value
            timeoutTask.cancel()
        } catch is CancellationError {
            purchaseError = "Couldn't confirm the purchase right now. We'll retry automatically next launch."
            throw StoreError.timeout
        } catch {
            purchaseError = "We got your purchase — syncing credits shortly. (\(error.localizedDescription))"
            throw error
        }
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { continue }
                guard let tx = try? await self.checkVerified(result) else { continue }
                // Only finish once the server accepts the receipt; otherwise
                // leave it in `Transaction.unfinished` so it replays next launch.
                do {
                    try await self.redeem(tx, productId: tx.productID)
                    await tx.finish()
                } catch {
                    print("[StoreKit] background redeem failed; will retry: \(error.localizedDescription)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:       throw StoreError.notVerified
        case .verified(let x):  return x
        }
    }

    enum StoreError: Error, LocalizedError {
        case notVerified
        case timeout
        var errorDescription: String? {
            switch self {
            case .notVerified: return "Transaction could not be verified by the App Store."
            case .timeout:     return "The request timed out."
            }
        }
    }

    /// Fire the App Store review prompt at a "magic moment". Apple gates this to
    /// ~3 prompts per user per year automatically — when over the cap, this silently no-ops.
    /// Call site is responsible for one-shot gating (e.g. `state.reviewPromptShown`).
    @MainActor
    static func requestReviewIfAvailable() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}

