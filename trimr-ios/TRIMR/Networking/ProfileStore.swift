import Foundation
import Combine

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profile: ProfileDTO?
    @Published private(set) var isLoading: Bool = false

    private var pollTimer: Timer?

    func load() async {
        guard let uid = Supa.client.auth.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let row: ProfileDTO = try await Supa.client
                .from("profiles")
                .select()
                .eq("user_id", value: uid.uuidString)
                .single()
                .execute()
                .value
            self.profile = row
        } catch {
            // A brand-new user may not have a profiles row yet — ignore silently; the
            // analyze-hairstyle / sign-up trigger creates it.
        }
    }

    /// Re-fetches `profile`. iOS validates Apple IAP via `validate-apple-iap` (which
    /// already updates the profiles row server-side), so a separate `check-subscription`
    /// ping is redundant here and was producing 404s — removed.
    func refresh() async {
        await load()
    }

    func startPolling(every seconds: TimeInterval = 60) {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func clear() {
        profile = nil
        stopPolling()
    }

    // Convenience
    var isPro: Bool { profile?.isPro ?? false }
    var lookCredits: Int { profile?.lookCredits ?? 0 }
    var canAnalyse: Bool { isPro || lookCredits >= 1 }
    var canTryOn: Bool { isPro || lookCredits >= 1 }
    var canColor: Bool { isPro || lookCredits >= 1 }
}
