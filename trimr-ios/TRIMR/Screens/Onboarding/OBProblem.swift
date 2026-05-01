import SwiftUI

struct OBProblem: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 24) {
                Text("Most men get the wrong haircut for their face.")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 48)

                Text("Wrong cut → six weeks of regret in every mirror, every photo, every meeting.")
                    .font(TFont.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                HStack(spacing: 14) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: 0x1C1812))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Theme.muted2)
                            )
                            .frame(height: 110)
                            .opacity(0.55)
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}
