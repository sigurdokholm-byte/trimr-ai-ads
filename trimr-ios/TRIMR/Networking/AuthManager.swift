import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading: Bool = true
    @Published var lastError: String?

    private var sessionTask: Task<Void, Never>?
    private let pendingMerge = PendingMergeStore()

    init() {
        sessionTask = Task { [weak self] in
            guard let self else { return }
            for await change in Supa.client.auth.authStateChanges {
                await MainActor.run {
                    self.session = change.session
                    self.isLoading = false
                }
            }
        }

        Task { [weak self] in
            let restored = try? await Supa.client.auth.session
            await MainActor.run {
                if self?.session == nil { self?.session = restored }
                self?.isLoading = false
            }
        }
    }

    var userId: UUID? { session?.user.id }
    var isSignedIn: Bool { session != nil }
    var isAnonymous: Bool { session?.user.isAnonymous ?? false }

    // MARK: - Anonymous

    /// Creates an anonymous Supabase session if no session exists yet.
    /// Used at app launch so onboarding (analyze, IAP) works before the user signs in.
    @discardableResult
    func signInAnonymouslyIfNeeded() async -> Bool {
        if session != nil { return true }
        do {
            _ = try await Supa.client.auth.signInAnonymously()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Ensures we have a valid (non-expired) JWT before calling edge functions.
    /// Refreshes the current session, or falls back to a fresh anonymous sign-in
    /// if the refresh token is gone/revoked. Call this immediately before any
    /// `functions.invoke` that requires `auth.getUser()` server-side.
    @discardableResult
    func ensureSession() async -> Bool {
        do {
            _ = try await Supa.client.auth.session
            return true
        } catch {
            do {
                _ = try await Supa.client.auth.signInAnonymously()
                return true
            } catch {
                lastError = error.localizedDescription
                return false
            }
        }
    }

    // MARK: - Anon → real merge

    /// Snapshots the current anonymous session into Keychain so we can transfer
    /// its credits + Apple IAP rows into the real account once sign-in lands.
    /// No-op if the current session is already a real (non-anonymous) one, or
    /// if there is no session at all.
    func snapshotAnonForMerge() async {
        guard isAnonymous else { return }
        guard let fresh = try? await Supa.client.auth.session else { return }
        guard fresh.user.isAnonymous else { return }
        let snap = PendingAnonSnapshot(
            anonUserId: fresh.user.id,
            anonAccessToken: fresh.accessToken,
            anonRefreshToken: fresh.refreshToken,
            capturedAt: Date(),
            attemptCount: 0
        )
        pendingMerge.save(snap)
    }

    /// Calls `merge-anonymous-account` if a snapshot is pending and the SDK now
    /// reports a different (non-anonymous) user. Idempotent and safe to call
    /// from `bootstrap()` as a crash-recovery retry.
    func attemptMerge() async {
        guard let snap = pendingMerge.load() else { return }
        // Use the SDK's source-of-truth — the published `session` property
        // updates asynchronously via authStateChanges, so right after a sign-in
        // call returns it can still report the old anon user.
        guard let fresh = try? await Supa.client.auth.session else { return }
        if fresh.user.id == snap.anonUserId {
            pendingMerge.clear()
            return
        }
        if fresh.user.isAnonymous { return } // still anon — sign-in didn't land
        do {
            let body = MergeAnonRequest(
                anonymousAccessToken: snap.anonAccessToken,
                anonymousRefreshToken: snap.anonRefreshToken
            )
            let _: MergeAnonResponse = try await Supa.client.functions
                .invoke("merge-anonymous-account", options: .init(body: body))
            pendingMerge.clear()
        } catch {
            pendingMerge.bumpAttempt()
            // Don't surface to UI — the next bootstrap() retries on next launch.
            print("[AuthManager] attemptMerge failed:", error.localizedDescription)
        }
    }

    // MARK: - Apple

    @discardableResult
    func signInWithApple(idTokenString: String, nonce: String) async -> Bool {
        await snapshotAnonForMerge()
        do {
            _ = try await Supa.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idTokenString, nonce: nonce)
            )
            await attemptMerge()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Google (browser-based OAuth via ASWebAuthenticationSession)

    /// Deep-link scheme registered in Info.plist. Must match the redirect URL
    /// added to the Google / Supabase OAuth allow-list.
    static let callbackScheme = "trimrai"
    static let callbackURL = URL(string: "trimrai://login-callback")!

    @discardableResult
    func signInWithGoogle() async -> Bool {
        await snapshotAnonForMerge()
        do {
            _ = try await Supa.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: Self.callbackURL,
                launchFlow: { url in
                    try await OAuthBrowser.launch(url: url, callbackURLScheme: Self.callbackScheme)
                }
            )
            await attemptMerge()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Email

    func signInWithEmail(email: String, password: String) async -> Bool {
        await snapshotAnonForMerge()
        do {
            _ = try await Supa.client.auth.signIn(email: email, password: password)
            await attemptMerge()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func signUpWithEmail(email: String, password: String) async -> Bool {
        await snapshotAnonForMerge()
        do {
            _ = try await Supa.client.auth.signUp(email: email, password: password)
            // When the project requires email confirmation, signUp succeeds but
            // creates no session — the SDK still reports the old anonymous user.
            // Don't claim success (which would finish onboarding and skip the
            // anon→real credit merge); tell the user to confirm first.
            let signedIn = (try? await Supa.client.auth.session)
                .map { !$0.user.isAnonymous } ?? false
            guard signedIn else {
                lastError = "Check your inbox to confirm your email, then tap “Log in”."
                return false
            }
            await attemptMerge()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Sign out / delete

    func signOut() async {
        do { try await Supa.client.auth.signOut() }
        catch { lastError = error.localizedDescription }
    }

    func deleteAccount() async -> Bool {
        do {
            let _: EmptyResponse = try await Supa.client.functions
                .invoke("delete-account", options: .init(body: [String: String]()))
            try await Supa.client.auth.signOut()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    deinit { sessionTask?.cancel() }
}

// MARK: - Nonce helper for Sign in with Apple

enum AppleSignInNonce {
    /// URL-safe random string used as the nonce on Apple sign-in.
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        let chars: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            _ = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            for r in randoms where remaining > 0 {
                if Int(r) < chars.count { result.append(chars[Int(r)]); remaining -= 1 }
            }
        }
        return result
    }

    /// SHA-256 hex of the nonce. Apple signs this; Supabase verifies it matches.
    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
