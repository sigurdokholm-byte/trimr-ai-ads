import SwiftUI
import AuthenticationServices

struct OBSignIn: View {
    let onDone: () -> Void

    @EnvironmentObject var auth: AuthManager
    @State private var currentNonce: String = ""
    @State private var showEmailSignUp = false
    @State private var showEmailLogIn = false
    @State private var inFlight = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Your dream haircut\nawaits")
                        .font(TFont.display(32)).tracking(-0.7).lineSpacing(-2)
                        .foregroundStyle(Theme.text)
                    Text("Save your looks and credits to any device.")
                        .font(TFont.body(15))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(5)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 10) {
                SignInWithAppleButton(.continue) { request in
                    let nonce = AppleSignInNonce.random()
                    currentNonce = nonce
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = AppleSignInNonce.sha256(nonce)
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .clipShape(Capsule())
                .disabled(inFlight)

                Button {
                    inFlight = true
                    Task {
                        let ok = await auth.signInWithGoogle()
                        inFlight = false
                        if ok { onDone() }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("G")
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(Color(hex: 0x4285F4))
                        Text("Continue with Google")
                    }
                    .font(TFont.body(15, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(inFlight)

                Button {
                    showEmailSignUp = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .font(.system(size: 15, weight: .regular))
                        Text("Continue with Email")
                    }
                    .font(TFont.body(15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color(hex: 0x1C1812))
                    .overlay(Capsule().stroke(Color.white.opacity(0.08)))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(inFlight)

                if let err = auth.lastError {
                    Text(err)
                        .font(TFont.body(11))
                        .foregroundStyle(Theme.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Button { showEmailLogIn = true } label: {
                    Text("Log in")
                        .font(TFont.body(13.5, weight: .medium))
                        .foregroundStyle(Theme.muted)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .disabled(inFlight)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showEmailSignUp) {
            OBEmailSignIn(initialMode: .signUp) { showEmailSignUp = false; onDone() }
                .environmentObject(auth)
        }
        .sheet(isPresented: $showEmailLogIn) {
            OBEmailSignIn(initialMode: .signIn) { showEmailLogIn = false; onDone() }
                .environmentObject(auth)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else { return }
            inFlight = true
            Task {
                let ok = await auth.signInWithApple(idTokenString: idToken, nonce: currentNonce)
                inFlight = false
                if ok { onDone() }
            }
        case .failure(let err):
            auth.lastError = err.localizedDescription
        }
    }
}
