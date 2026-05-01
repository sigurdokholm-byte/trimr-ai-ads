import SwiftUI

struct OBBridge: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)
            Spacer()
            Text("OBBridge placeholder · \(name)")
                .font(TFont.display(20))
                .foregroundStyle(Theme.text)
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
