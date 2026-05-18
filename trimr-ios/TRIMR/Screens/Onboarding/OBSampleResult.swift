import SwiftUI

/// Onboarding screen 1 of the standard result preview: the real in-app
/// `ResultView` rendered in `.card` mode (photo + name/score + compatibility
/// breakdown) with its built-in sample data, plus a small headline explaining
/// what the user is looking at and a Continue button to advance.
struct OBSampleResult: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                OBHeader(progress: progress, onBack: onBack)

                VStack(alignment: .leading, spacing: 6) {
                    Text("here's a walk through of what you get")
                        .font(TFont.display(24))
                        .tracking(-0.5)
                        .foregroundStyle(Theme.text)
                    Text("")
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 6)

                ResultView(section: .card)
            }

            continueBar(onNext)
        }
        .background(Theme.bgDeep.ignoresSafeArea())
    }
}

/// Shared bottom Continue affordance for the onboarding result screens.
@ViewBuilder
func continueBar(_ action: @escaping () -> Void) -> some View {
    VStack(spacing: 0) {
        LinearGradient(
            colors: [Theme.bgDeep.opacity(0), Theme.bgDeep],
            startPoint: .top, endPoint: .bottom
        )
        .frame(height: 32)
        .allowsHitTesting(false)

        Button(action: action) {
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
        .background(Theme.bgDeep)
    }
}
