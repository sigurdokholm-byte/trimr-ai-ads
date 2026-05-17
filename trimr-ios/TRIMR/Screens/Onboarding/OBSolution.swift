import SwiftUI

/// The Solution. The direct narrative answer to OBProblem's pain, in the same
/// display-line + inline-gold voice — no header, no cards — so the two screens
/// read as one continuous thought. Mirrors Problem's "wrong cut / wrong face"
/// beat-for-beat as "right cut / your face" so the payoff lands by echo.
struct OBSolution: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 22) {
                Spacer().frame(height: 28)

                (
                    Text("trimr finds the ")
                        .foregroundStyle(Theme.text)
                    + Text("right cut")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)

                (
                    Text("for ")
                        .foregroundStyle(Theme.text)
                    + Text("your face")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)

                (
                    Text("in ")
                        .foregroundStyle(Theme.text)
                    + Text("30 seconds")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)

                Spacer().frame(height: 12)

                Text("no guesswork. no 6-week regret. just the one that actually fits.")
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("continue")
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
