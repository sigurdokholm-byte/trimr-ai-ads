import SwiftUI

/// Calm pivot screen between bombshell and quizzes. Mau-style: warm,
/// conversational, names the user, ends with a forward-momentum CTA.
struct OBBridge: View {
    let name: String
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 18) {
                Spacer().frame(height: 32)

                Text("alright\(name.isEmpty ? "." : ", \(name).")")
                    .font(TFont.display(34))
                    .tracking(-0.6)
                    .foregroundStyle(Theme.text)

                (
                    Text("let's ")
                        .foregroundStyle(Theme.text)
                    + Text("fix")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.bold)
                    + Text(" it.")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(34))
                .tracking(-0.6)

                Spacer().frame(height: 8)

                (
                    Text("5 minutes. ")
                        .foregroundStyle(Theme.muted)
                    + Text("no fluff. ")
                        .foregroundStyle(Theme.muted)
                    + Text("just your cut.")
                        .foregroundStyle(Theme.muted)
                )
                .font(TFont.body(16))
                .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .opacity(contentOpacity)

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
            .opacity(contentOpacity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { contentOpacity = 1 }
        }
    }
}
