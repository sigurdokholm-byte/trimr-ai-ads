import SwiftUI

/// Onboarding "analyzing" placeholder. Plays the rotating-status animation for
/// 10s without calling any backend. The real analyze-hairstyle call is deferred
/// to OBFullReveal — after the user has paid and has a look credit to spend.
struct OBAnalyzing: View {
    let onComplete: () -> Void

    @State private var didStart: Bool = false

    var body: some View {
        AnalyzingChecklistView()
            .task {
                guard !didStart else { return }
                didStart = true
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !Task.isCancelled {
                    await MainActor.run { onComplete() }
                }
            }
    }
}
