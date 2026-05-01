import SwiftUI

struct OBFreeReveal: View {
    let name: String
    let analysis: AnalyzeResponse?
    let userImage: UIImage?
    let onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text("OBFreeReveal placeholder")
                .font(TFont.display(22))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
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
