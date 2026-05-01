import SwiftUI

struct OBBombshell: View {
    let onNext: () -> Void
    let progress: Double
    let firstImpressions: Int
    let firstStyleGoal: String?

    @State private var numberScale: CGFloat = 0.8
    @State private var subOpacity: Double = 0

    private var bodyCopy: String {
        let goal = firstStyleGoal ?? "look your best"
        return "People judge your face in 7 seconds. Hair is 55% of that. You answered \"\(goal)\" — let's make those impressions count."
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: {}, showBack: false)

            VStack(spacing: 18) {
                Spacer().frame(height: 12)
                Text("BASED ON YOUR ANSWERS")
                    .labelMono()
                Text(firstImpressions.formatted())
                    .font(TFont.display(72))
                    .tracking(-1)
                    .foregroundStyle(Theme.goldGlow)
                    .shadow(color: Theme.gold.opacity(0.4), radius: 20, y: 0)
                    .scaleEffect(numberScale)
                    .animation(.spring(response: 0.55, dampingFraction: 0.7), value: numberScale)
                Text("first impressions left in your life.")
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .opacity(subOpacity)
                Text(bodyCopy)
                    .font(TFont.body(14))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .opacity(subOpacity)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("I'm in")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(subOpacity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            numberScale = 1
            withAnimation(.easeOut(duration: 0.45).delay(0.6)) {
                subOpacity = 1
            }
        }
    }
}
