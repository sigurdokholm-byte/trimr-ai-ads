import SwiftUI

/// "how it works" — the 3-step explainer shown right after the proof chart
/// and just before the photo climax, so the user knows exactly what happens
/// when they invest their selfie. Numbered gold tokens, emoji anchors.
struct OBHowItWorks: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Step { let n: Int; let emoji: String; let title: String }
    private let steps: [Step] = [
        .init(n: 1, emoji: "🔍", title: "scan your face shape"),
        .init(n: 2, emoji: "✂️", title: "find your top match"),
        .init(n: 3, emoji: "🪞", title: "see yourself in each cut"),
    ]

    @State private var visible: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 22) {
                Spacer().frame(height: 32)

                Text("how it works")
                    .font(TFont.display(30))
                    .tracking(-0.6)
                    .foregroundStyle(Theme.text)
                    .reveal(1, visible)

                VStack(spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.element.n) { idx, step in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Theme.goldGlow)
                                    .shadow(color: Theme.gold.opacity(0.4), radius: 6)
                                Text("\(step.n)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x0A0804))
                            }
                            .frame(width: 30, height: 30)

                            Text(step.emoji).font(.system(size: 19))

                            Text(step.title)
                                .font(TFont.body(16, weight: .semibold))
                                .foregroundStyle(Theme.text)

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(
                                    colors: [Color(hex: 0x1B1610), Theme.card2],
                                    startPoint: .top, endPoint: .bottom))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Theme.gold.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .reveal(idx + 2, visible)
                    }
                }

                (
                    Text("your perfect haircut, in ")
                        .foregroundStyle(Theme.muted)
                    + Text("30 seconds")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.semibold)
                    + Text(". no guesswork.")
                        .foregroundStyle(Theme.muted)
                )
                .font(TFont.body(14))
                .padding(.top, 4)
                .reveal(5, visible)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("let me see")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .reveal(5, visible)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            for i in 1...5 {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 380_000_000)
                if Task.isCancelled { return }
                visible = i
            }
        }
    }
}

// MARK: - Sequential reveal helper

private extension View {
    func reveal(_ index: Int, _ visible: Int) -> some View {
        let shown = visible >= index
        return self
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: visible)
    }
}
