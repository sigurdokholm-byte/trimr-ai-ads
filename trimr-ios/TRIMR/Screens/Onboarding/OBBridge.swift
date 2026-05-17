import SwiftUI

/// The Bridge — recovery beat right after the Bombshell. Mau's three moves:
/// give them hope (it doesn't have to be this way), a small achievable ask
/// (just 5 minutes), then frame what's next as a personalized plan (a plan
/// for you). Lines fade in sequentially, then the CTA.
struct OBBridge: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0
    @State private var line3Opacity: Double = 0
    @State private var ctaOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 22) {
                Spacer().frame(height: 32)

                (
                    Text("it doesn't have to be this way")
                        .foregroundStyle(Theme.text)
                    + Text(name.isEmpty ? "." : ", \(name).")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
                .lineSpacing(4)
                .opacity(line1Opacity)

                (
                    Text("do you have just ")
                        .foregroundStyle(Theme.text)
                    + Text("5 minutes")
                        .foregroundStyle(Theme.gold)
                    + Text("?")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
                .opacity(line2Opacity)

                (
                    Text("let's find the perfect cut for ")
                        .foregroundStyle(Theme.text)
                    + Text("you")
                        .foregroundStyle(Theme.gold)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
                .opacity(line3Opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("let's go")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(ctaOpacity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.2))  { line1Opacity = 1 }
            withAnimation(.easeOut(duration: 0.45).delay(0.75)) { line2Opacity = 1 }
            withAnimation(.easeOut(duration: 0.45).delay(1.3))  { line3Opacity = 1 }
            withAnimation(.easeOut(duration: 0.45).delay(1.85)) { ctaOpacity = 1 }
        }
    }
}
