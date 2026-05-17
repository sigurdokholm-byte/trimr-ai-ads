import SwiftUI

/// Opens the narrative arc with a calm, conversational problem statement.
/// Mau-style: lowercase, sentence-fragment lines, gold-highlighted key phrases
/// woven inline. No silhouette cards — the typography carries the screen.
struct OBProblem: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 22) {
                Spacer().frame(height: 28)

                (
                    Text("most men get the ")
                        .foregroundStyle(Theme.text)
                    + Text("wrong cut")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)

                (
                    Text("for the ")
                        .foregroundStyle(Theme.text)
                    + Text("wrong face")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)

                (
                    Text("and they ")
                        .foregroundStyle(Theme.text)
                    + Text("don't know it")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)

                Spacer().frame(height: 12)

                (
                    Text("don't be ")
                        .foregroundStyle(Theme.text)
                    + Text("that man")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
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
