import SwiftUI

struct OBBridge: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var dotX: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 22) {
                Spacer().frame(height: 36)
                Text("It doesn't have to be this way\(name.isEmpty ? "." : ", \(name).")")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 24)

                Text("Give us 5 minutes. We'll build your style plan.")
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                GeometryReader { geo in
                    let track = geo.size.width - 16
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0x2A2520))
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 14, height: 14)
                            .offset(x: dotX, y: -4)
                            .shadow(color: Theme.gold.opacity(0.6), radius: 8)
                    }
                    .frame(height: 6)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            dotX = max(track, 0)
                        }
                    }
                }
                .frame(height: 22)
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Let's build it")
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
