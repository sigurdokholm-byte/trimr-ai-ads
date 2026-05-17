import SwiftUI

struct OBGoal: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: Int?

    private let options = [
        "Just curious to try new hairstyles",
        "I had a bad haircut and want to avoid it again",
        "I'm going to the salon soon and want to prepare",
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 28) {
                Text("what brings you to trimr?")
                    .font(TFont.display(24))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                VStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                        let selected = value == idx
                        Button { value = idx } label: {
                            Text(opt)
                                .font(TFont.body(15, weight: .medium))
                                .foregroundStyle(selected ? Theme.gold : Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(selected ? Theme.gold.opacity(0.08) : Color(hex: 0x1C1812))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(selected ? Theme.gold.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button { if value != nil { onNext() } } label: {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(value == nil ? Color(hex: 0x1A1610) : Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(value == nil ? Color(hex: 0x5A544A) : Theme.gold)
                    .clipShape(Capsule())
                    .opacity(value == nil ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}
