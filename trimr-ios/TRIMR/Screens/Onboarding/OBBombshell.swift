import SwiftUI

struct OBBombshell: View {
    let onNext: () -> Void
    let progress: Double
    let firstImpressions: Int
    let firstStyleGoal: String?

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: {}, showBack: false)
            Spacer()
            Text("OBBombshell placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
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
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}
