import SwiftUI

struct OBHello: View {
    let onNext: () -> Void

    @State private var greetingScale: CGFloat = 0.92
    @State private var greetingOpacity: Double = 0
    @State private var hintOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // Subtle radial warmth from center
            RadialGradient(
                colors: [Theme.gold.opacity(0.06), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("hey.")
                    .font(.system(size: 96, weight: .black, design: .default))
                    .tracking(-3)
                    .foregroundStyle(Theme.goldGlow)
                    .shadow(color: Theme.gold.opacity(0.35), radius: 28, y: 0)
                    .scaleEffect(greetingScale)
                    .opacity(greetingOpacity)

                Spacer()

                Text("tap to continue")
                    .font(TFont.mono(11, weight: .medium))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.muted)
                    .opacity(hintOpacity)
                    .padding(.bottom, 48)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onNext()
        }
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
                greetingScale = 1
                greetingOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.45).delay(0.9)) {
                hintOpacity = 1
            }
        }
    }
}
