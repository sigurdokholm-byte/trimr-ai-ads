import SwiftUI

struct OBReflection1: View {
    let hairType: HairType?
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private var headline: String {
        guard let hairType else { return "Let's keep going…" }
        return "So your hair is \(hairType.rawValue)…"
    }

    private var bodyCopy: String {
        switch hairType {
        case .straight: return "Straight hair shows the cut perfectly — every detail matters."
        case .wavy:     return "Wavy hair has the most range — the right cut transforms it."
        case .curly:    return "Curly hair has the most styling range — most men just don't know how to use it."
        case .coily:    return "Coily hair holds shape better than any other type — the cut decides everything."
        case .none:     return "We'll learn more about your hair as we go."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 18) {
                Spacer().frame(height: 48)
                Text(headline)
                    .font(TFont.display(26))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)

                Text(bodyCopy)
                    .font(TFont.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
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
        .task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            onNext()
        }
    }
}
