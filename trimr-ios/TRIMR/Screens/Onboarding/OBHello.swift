import SwiftUI

/// Soft greeting — first thing the user sees after splash. Mimics Mau Baron's
/// "hey." pattern (full-bleed warm tone, single word, tap-anywhere to advance).
/// Adapted to TRIMR: dark bg with intense gold radial that evokes the warm
/// orange feel without breaking the brand's gold/black identity.
struct OBHello: View {
    let onNext: () -> Void

    @State private var greetingScale: CGFloat = 0.94
    @State private var greetingOpacity: Double = 0
    @State private var hintOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.gold.opacity(0.22), Theme.gold.opacity(0.05), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Text("hey.")
                    .font(.system(size: 84, weight: .black, design: .default))
                    .tracking(-2.5)
                    .foregroundStyle(Theme.text)
                    .scaleEffect(greetingScale)
                    .opacity(greetingOpacity)
                Spacer()

                HStack(spacing: 6) {
                    Spacer()
                    Text("tap to continue")
                        .font(TFont.body(13, weight: .medium))
                        .foregroundStyle(Theme.muted)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
                .opacity(hintOpacity)
                .padding(.trailing, 28)
                .padding(.bottom, 36)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onNext() }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
                greetingScale = 1
                greetingOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
                hintOpacity = 1
            }
        }
    }
}
