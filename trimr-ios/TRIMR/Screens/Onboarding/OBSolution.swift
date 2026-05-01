import SwiftUI

/// "How it works" — Mau-style numbered list with gold accent dots, single
/// closing caption beneath. Lowercase headline matches the conversational tone.
struct OBSolution: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Step { let n: Int; let title: String; let emoji: String }
    private let steps: [Step] = [
        .init(n: 1, title: "scan your face shape",            emoji: "🔍"),
        .init(n: 2, title: "rank 3 cuts that fit it",          emoji: "✂️"),
        .init(n: 3, title: "see yourself in each cut",         emoji: "🪞"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 22) {
                Spacer().frame(height: 36)

                Text("how it works")
                    .font(TFont.display(30))
                    .tracking(-0.5)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    ForEach(steps, id: \.n) { step in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Theme.gold)
                                Text("\(step.n)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x0A0804))
                            }
                            .frame(width: 28, height: 28)

                            HStack(spacing: 8) {
                                Text(step.emoji).font(.system(size: 18))
                                Text(step.title)
                                    .font(TFont.body(16, weight: .semibold))
                                    .foregroundStyle(Theme.text)
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Theme.card2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.gold.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                (
                    Text("your perfect haircut, in ")
                        .foregroundStyle(Theme.muted)
                    + Text("90 seconds")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.semibold)
                    + Text(". no guesswork.")
                        .foregroundStyle(Theme.muted)
                )
                .font(TFont.body(14))
                .padding(.top, 6)
            }
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("got it")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.3), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}
