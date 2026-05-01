import SwiftUI

/// Mid-quiz mirror screen — reflects the user's hair-type answer back with
/// gold-highlighted keyword. Mau-style: short, lowercase, conversational,
/// auto-advances after 4s but lets the user tap forward.
struct OBReflection1: View {
    let hairType: HairType?
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private var headlineParts: (String, String) {
        switch hairType {
        case .straight: return ("so your hair is ", "straight")
        case .wavy:     return ("so your hair is ", "wavy")
        case .curly:    return ("so your hair is ", "curly")
        case .coily:    return ("so your hair is ", "coily")
        case .none:     return ("let's keep going", "")
        }
    }

    private var bodyCopy: String {
        switch hairType {
        case .straight: return "straight hair shows the cut perfectly. every detail matters."
        case .wavy:     return "wavy hair has the most range. the right cut transforms it."
        case .curly:    return "curly hair has the most styling potential. most men just don't know how to use it."
        case .coily:    return "coily hair holds shape better than any other type. the cut decides everything."
        case .none:     return "we'll learn more about your hair as we go."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 56)

                if hairType != nil {
                    (
                        Text(headlineParts.0)
                            .foregroundStyle(Theme.text)
                        + Text(headlineParts.1)
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.black)
                        + Text(".")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.display(28))
                    .tracking(-0.5)
                } else {
                    Text(headlineParts.0)
                        .font(TFont.display(28))
                        .tracking(-0.5)
                        .foregroundStyle(Theme.text)
                }

                Text(bodyCopy)
                    .font(TFont.body(15))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(4)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("continue")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.3), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled {
                onNext()
            }
        }
    }
}
