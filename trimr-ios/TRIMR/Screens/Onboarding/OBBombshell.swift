import SwiftUI

/// The "AHA" moment — Mau-style stat-driven body copy. The hero number
/// dominates the screen, then a sequence of conversational stat lines with
/// gold-highlighted phrases lead to a personal question.
/// No back chevron — momentum-only screen.
struct OBBombshell: View {
    let onNext: () -> Void
    let progress: Double
    let firstImpressions: Int
    let firstStyleGoal: String?

    @State private var numberScale: CGFloat = 0.86
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0
    @State private var line3Opacity: Double = 0
    @State private var ctaOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: {}, showBack: false)

            VStack(alignment: .leading, spacing: 28) {
                Spacer().frame(height: 12)

                // Hero number block
                VStack(alignment: .leading, spacing: 6) {
                    Text("based on what you've shared,")
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)

                    Text(firstImpressions.formatted())
                        .font(TFont.display(72))
                        .tracking(-1.5)
                        .foregroundStyle(Theme.goldGlow)
                        .shadow(color: Theme.gold.opacity(0.45), radius: 22, y: 0)
                        .scaleEffect(numberScale)

                    Text("first impressions left in your life.")
                        .font(TFont.body(15))
                        .foregroundStyle(Theme.text)
                }

                // Mau-style stat lines, lowercase, gold-highlighted phrases
                VStack(alignment: .leading, spacing: 16) {
                    (
                        Text("each one takes ")
                            .foregroundStyle(Theme.text)
                        + Text("7 seconds")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.bold)
                        + Text(".")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.body(18, weight: .medium))
                    .opacity(line1Opacity)

                    (
                        Text("and ")
                            .foregroundStyle(Theme.text)
                        + Text("55%")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.bold)
                        + Text(" of every judgment is your ")
                            .foregroundStyle(Theme.text)
                        + Text("hair")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.bold)
                        + Text(".")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.body(18, weight: .medium))
                    .opacity(line2Opacity)

                    (
                        Text("so — how many of those do you want to ")
                            .foregroundStyle(Theme.text)
                        + Text("own")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.bold)
                        + Text("?")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.body(18, weight: .medium))
                    .opacity(line3Opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("i'm in")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.4), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(ctaOpacity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                numberScale = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.7))  { line1Opacity = 1 }
            withAnimation(.easeOut(duration: 0.4).delay(1.15)) { line2Opacity = 1 }
            withAnimation(.easeOut(duration: 0.4).delay(1.6))  { line3Opacity = 1 }
            withAnimation(.easeOut(duration: 0.4).delay(2.05)) { ctaOpacity = 1 }
        }
    }
}
