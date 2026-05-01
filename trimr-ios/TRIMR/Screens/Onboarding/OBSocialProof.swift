import SwiftUI

/// Final pre-paywall trust screen. Mau-style: lowercase headline with
/// gold-highlighted target audience, laurel "#1" badge, 5 stars + member
/// count, two reviews with bold UPPERCASE titles + body copy.
struct OBSocialProof: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Review {
        let title: String
        let body: String
    }

    private let reviews: [Review] = [
        .init(title: "GAME CHANGER.",
              body: "showed my barber the photo and got the exact cut. best £8 i've ever spent."),
        .init(title: "FINALLY.",
              body: "no more bad-cut anxiety. wish i had this 10 years ago."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 28)

                    (
                        Text("trimr was designed for ")
                            .foregroundStyle(Theme.text)
                        + Text("men like you")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.black)
                        + Text(".")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.display(28))
                    .tracking(-0.5)

                    Spacer().frame(height: 8)

                    Text("reviews from men using trimr.")
                        .font(TFont.body(14))
                        .foregroundStyle(Theme.muted)

                    Spacer().frame(height: 28)

                    // Laurel + #1 app badge
                    laurelBadge
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: 14)

                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: 8)

                    HStack(spacing: 6) {
                        Text("✂️ 💈 🪞")
                            .font(.system(size: 16))
                        Text("+ 47,000 men")
                            .font(TFont.body(13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: 28)

                    VStack(spacing: 12) {
                        ForEach(reviews.indices, id: \.self) { i in
                            reviewCard(reviews[i])
                        }
                    }

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 24)
            }

            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text("join trimr")
                        .font(TFont.body(16, weight: .semibold))
                    Text("✂️")
                        .font(.system(size: 14))
                }
                .foregroundStyle(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Theme.goldGlow)
                .clipShape(Capsule())
                .shadow(color: Theme.gold.opacity(0.4), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var laurelBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 56))
                .foregroundStyle(Theme.gold)
            VStack(spacing: 2) {
                Text("the #1")
                    .font(TFont.display(15))
                    .tracking(-0.2)
                    .foregroundStyle(Theme.text)
                Text("haircut app")
                    .font(TFont.display(15))
                    .tracking(-0.2)
                    .foregroundStyle(Theme.text)
            }
            Image(systemName: "laurel.trailing")
                .font(.system(size: 56))
                .foregroundStyle(Theme.gold)
        }
    }

    private func reviewCard(_ r: Review) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.gold)
                }
            }

            Text(r.title)
                .font(.system(size: 15, weight: .black))
                .tracking(0.5)
                .foregroundStyle(Theme.text)

            Text(r.body)
                .font(TFont.body(13))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
