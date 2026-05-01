import SwiftUI

struct OBSolution: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Step { let n: Int; let title: String }
    private let steps: [Step] = [
        .init(n: 1, title: "Scan your face shape"),
        .init(n: 2, title: "Rank 3 cuts that match it"),
        .init(n: 3, title: "See yourself in each cut before you book"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 32) {
                Text("TRIMR fixes that in 90 seconds.")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 48)

                VStack(spacing: 14) {
                    ForEach(steps, id: \.n) { step in
                        HStack(spacing: 16) {
                            Text("\(step.n)")
                                .font(TFont.display(20))
                                .foregroundStyle(Theme.gold)
                                .frame(width: 38, height: 38)
                                .background(Color(hex: 0x1C1812))
                                .overlay(Circle().stroke(Theme.gold.opacity(0.4), lineWidth: 1.5))
                                .clipShape(Circle())
                            Text(step.title)
                                .font(TFont.body(15, weight: .medium))
                                .foregroundStyle(Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .padding(18)
                        .background(Color(hex: 0x1C1812))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Got it")
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
