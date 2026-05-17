import SwiftUI
import UIKit

/// Post-purchase reveal. The actual analyze-hairstyle backend call happens HERE
/// (after the paywall) — by this point the user has paid and has a look credit
/// to spend, so HTTP 402 cannot recur. While the call runs we show a brief
/// "generating your look" state, then hand off to ResultView with the response.
struct OBFullReveal: View {
    let name: String
    let analysis: AnalyzeResponse?
    let userImage: UIImage
    let preferences: [String: String]
    let onAnalyzed: (AnalyzeResponse) -> Void
    let onContinue: () -> Void

    @EnvironmentObject private var auth: AuthManager
    @State private var localAnalysis: AnalyzeResponse?
    @State private var errorMessage: String?
    @State private var didStart: Bool = false
    @State private var reviewPromptScheduled: Bool = false

    var body: some View {
        ZStack {
            if let resp = localAnalysis ?? analysis {
                resultLayer(response: resp)
            } else if let err = errorMessage {
                errorLayer(message: err)
            } else {
                AnalyzingChecklistView()
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .task {
            guard !didStart else { return }
            didStart = true
            if analysis == nil {
                await runAnalysis()
            }
        }
    }

    private func resultLayer(response: AnalyzeResponse) -> some View {
        ZStack(alignment: .bottom) {
            ResultView(response: response, userImage: userImage)

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Theme.bgDeep.opacity(0), Theme.bgDeep],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 32)
                .allowsHitTesting(false)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(TFont.body(16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Theme.gold).clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .background(Theme.bgDeep)
            }
        }
    }

    private func errorLayer(message: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.gold)
            Text("Hit a snag")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Text(message)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                errorMessage = nil
                Task { await runAnalysis() }
            } label: {
                Text("Try Again")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func runAnalysis() async {
        guard let base64 = userImage.base64DataURL(maxDim: 1024, quality: 0.85) else {
            await MainActor.run { errorMessage = "Couldn't read your photo. Try retaking it." }
            return
        }
        guard await auth.ensureSession() else {
            await MainActor.run {
                errorMessage = auth.lastError ?? "Couldn't start a session. Check your connection."
            }
            return
        }
        do {
            let body = AnalyzeRequest(image: base64, preferences: preferences)
            let resp: AnalyzeResponse = try await Supa.client.functions
                .invoke("analyze-hairstyle", options: .init(body: body))
            await MainActor.run {
                localAnalysis = resp
                onAnalyzed(resp)
                scheduleReviewPrompt()
            }
        } catch {
            await MainActor.run { errorMessage = (error as NSError).localizedDescription }
        }
    }

    /// 10s after the first paid look reveals, trigger Apple's in-app review
    /// prompt. SKStoreReviewController is silently capped at ~3/user/year so
    /// repeated reveals won't actually re-prompt.
    private func scheduleReviewPrompt() {
        guard !reviewPromptScheduled else { return }
        reviewPromptScheduled = true
        Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if !Task.isCancelled {
                await MainActor.run { StoreKitManager.requestReviewIfAvailable() }
            }
        }
    }
}
