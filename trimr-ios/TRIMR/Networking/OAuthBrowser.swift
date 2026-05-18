import Foundation
import AuthenticationServices
import UIKit

/// Wrapper around `ASWebAuthenticationSession` exposed as async/await, plus the
/// presentation-anchor plumbing Apple requires. Used by Supabase's
/// `signInWithOAuth` launch-flow closure.
enum OAuthBrowser {
    @MainActor
    static func launch(url: URL, callbackURLScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callback, error in
                if let error {
                    cont.resume(throwing: error)
                } else if let callback {
                    cont.resume(returning: callback)
                } else {
                    cont.resume(throwing: URLError(.badServerResponse))
                }
            }
            session.presentationContextProvider = OAuthPresenter.shared
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() {
                cont.resume(throwing: URLError(.cannotConnectToHost))
            }
        }
    }
}

@MainActor
final class OAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresenter()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes.first { $0.activationState == .foregroundActive }
            ?? windowScenes.first
        if let keyWindow = activeScene?.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        if let window = activeScene?.windows.first {
            return window
        }
        assertionFailure("OAuthPresenter: no active UIWindow available to present ASWebAuthenticationSession")
        return ASPresentationAnchor()
    }
}
