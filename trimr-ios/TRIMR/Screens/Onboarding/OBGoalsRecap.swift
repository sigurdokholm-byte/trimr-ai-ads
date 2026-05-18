import SwiftUI

/// "goals recap → you're in the right place" — premium goal cards that float
/// slightly crooked (alternating tilt + offset) for a hand-stacked feel, then
/// a closing reassurance block + continue CTA. Static copy, no state.
/// Shown in the social-proof slot.
struct OBGoalsRecap: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Goal { let emoji: String; let title: String; let body: String }
    private let goals: [Goal] = [
        .init(emoji: "💈",
              title: "a cut that fits my face",
              body: "we match a haircut to your exact face shape and hair — not guesswork, not trends that don't suit you."),
        .init(emoji: "✂️",
              title: "walk into the barber sure",
              body: "you'll get a clear barber brief and a photo to show, so you never settle for 'just a trim' again."),
        .init(emoji: "🔥",
              title: "look my best every day",
              body: "the right cut works with your hair, so good days stop being luck."),
    ]

    // Per-card crooked float: gentle alternating tilt + horizontal nudge.
    private let tilts: [Double] = [-2.5, 1.8, -1.4]
    private let nudges: [CGFloat] = [-7, 8, -4]

    @State private var visible: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Spacer().frame(height: 26)

                    ForEach(Array(goals.enumerated()), id: \.offset) { idx, goal in
                        HStack(alignment: .top, spacing: 14) {
                            Text(goal.emoji).font(.system(size: 26))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(goal.title)
                                    .font(TFont.body(17, weight: .bold))
                                    .foregroundStyle(Theme.text)
                                Text(goal.body)
                                    .font(TFont.body(13))
                                    .foregroundStyle(Theme.muted)
                                    .lineSpacing(3)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [Color(hex: 0x1E1812), Theme.card2],
                                    startPoint: .top, endPoint: .bottom))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(
                                    colors: [Theme.gold.opacity(0.28), Theme.gold.opacity(0.07)],
                                    startPoint: .top, endPoint: .bottom), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
                        .rotationEffect(.degrees(tilts[idx % tilts.count]))
                        .offset(x: nudges[idx % nudges.count])
                        .reveal(idx + 1, visible)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("you're in the right place")
                            .font(TFont.display(24))
                            .tracking(-0.5)
                            .foregroundStyle(Theme.text)
                        Text("tens of thousands have started with the same goals, and trimr helped them get there.")
                            .font(TFont.body(14))
                            .foregroundStyle(Theme.muted)
                            .lineSpacing(3)
                    }
                    .padding(.top, 16)
                    .reveal(goals.count + 1, visible)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Button(action: onNext) {
                Text("continue")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            for i in 1...(goals.count + 1) {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 380_000_000)
                if Task.isCancelled { return }
                visible = i
            }
        }
    }
}

// MARK: - Sequential reveal helper

private extension View {
    func reveal(_ index: Int, _ visible: Int) -> some View {
        let shown = visible >= index
        return self
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: visible)
    }
}
