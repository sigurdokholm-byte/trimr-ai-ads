import SwiftUI

struct OBWelcome: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.gold.opacity(0.22), .clear],
                center: .top, startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                OBHeader(progress: progress, onBack: onBack)

                Spacer().frame(height: 70)

                VStack(spacing: 22) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                        Text("WELCOME")
                            .font(TFont.mono(11, weight: .bold))
                            .tracking(2.2)
                            .foregroundStyle(Theme.gold)
                    }

                    Text("Nice to meet you,\n\(displayName)!")
                        .font(TFont.display(34))
                        .tracking(-0.6)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.text)
                        .lineSpacing(2)

                    Text("In the next 2 minutes, you'll discover how to never leave a salon disappointed again.")
                        .font(TFont.body(15))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 30)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    onNext()
                } label: {
                    Text("Continue")
                        .font(TFont.body(16, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.goldGlow)
                        .clipShape(Capsule())
                        .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }

    private var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "there" : trimmed
    }
}
