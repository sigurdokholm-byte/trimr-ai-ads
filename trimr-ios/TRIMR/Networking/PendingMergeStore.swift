import Foundation
import Security

/// One pending anonymous → real account merge waiting to be applied.
/// Persisted in Keychain so a crash / lost-network between sign-in and the
/// `merge-anonymous-account` edge-function call doesn't strand paid credits
/// on the orphan anon profile — `bootstrap()` retries on every launch.
struct PendingAnonSnapshot: Codable, Equatable {
    let anonUserId: UUID
    let anonAccessToken: String      // Supabase JWT (HS256), validated server-side
    let anonRefreshToken: String     // optional refresh; empty string if missing
    let capturedAt: Date
    var attemptCount: Int            // bumped on each failed merge attempt
}

/// Keychain-backed single-slot store for `PendingAnonSnapshot`. Tokens are
/// credentials, so they go in Keychain (not UserDefaults). One snapshot at a
/// time — a fresh `save(_:)` overwrites the previous entry.
final class PendingMergeStore {
    private let service = "ai.trimr.pendingMerge"
    private let account = "snapshot"

    func save(_ snapshot: PendingAnonSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let baseQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        // Try update first; if no entry exists, fall through to add.
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func load() -> PendingAnonSnapshot? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let snapshot = try? JSONDecoder().decode(PendingAnonSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    func bumpAttempt() {
        guard var snap = load() else { return }
        snap.attemptCount += 1
        save(snap)
    }
}
