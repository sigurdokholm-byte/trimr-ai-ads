import SwiftUI

struct OBReviews: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Review {
        let name: String
        let stars: Int
        let headline: String
        let body: String
        let image: String
    }
    private let testimonials: [Review] = [
        .init(name: "Emma R.",   stars: 5, headline: "GAME CHANGER.",
              body: "I finally found a cut that fits my square face shape. I am super happy. This app saved me from another bad haircut.",
              image: "ReviewEmma"),
        .init(name: "Marcus T.", stars: 5, headline: "NO MORE REGRET.",
              body: "I've had haircut regret before. This made me feel way safer before booking my appointment.",
              image: "ReviewMarcus"),
        .init(name: "Jordan P.", stars: 5, headline: "EXACTLY LIKE THE PIC.",
              body: "Walked into the barber with a screenshot and walked out looking exactly like it. First time that's ever happened.",
              image: "ReviewJordan"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    (
                        Text("trimr was designed for ")
                            .foregroundStyle(Theme.text)
                        + Text("men like you")
                            .foregroundStyle(Theme.gold)
                        + Text(".")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.display(28)).tracking(-0.6)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                    Text("reviews from real trimr users.")
                        .font(TFont.body(13))
                        .foregroundStyle(Theme.muted)

                    // Laurel #1 badge
                    HStack(spacing: 10) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 38))
                            .foregroundStyle(Theme.gold)
                        VStack(spacing: 1) {
                            Text("the #1")
                            Text("hair app")
                        }
                        .font(TFont.body(13, weight: .bold))
                        .foregroundStyle(Theme.text)
                        Image(systemName: "laurel.trailing")
                            .font(.system(size: 38))
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(.top, 2)

                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Text("★").font(.system(size: 18)).foregroundStyle(Theme.gold)
                        }
                    }

                    HStack(spacing: 12) {
                        ZStack {
                            avatar("ReviewEmma", offset: 0)
                            avatar("ReviewMarcus", offset: 22)
                            avatar("ReviewJordan", offset: 44)
                        }
                        .frame(width: 76, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("+55.000").font(TFont.display(16)).tracking(-0.3).foregroundStyle(Theme.text)
                            Text("happy users worldwide").font(TFont.body(10)).foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(.bottom, 4)

                    VStack(spacing: 10) {
                        ForEach(Array(testimonials.enumerated()), id: \.offset) { _, t in
                            HStack(alignment: .top, spacing: 12) {
                                Image(t.image).resizable().scaledToFill()
                                    .frame(width: 52, height: 52).clipped()
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(String(repeating: "★", count: t.stars))
                                        .font(.system(size: 11)).foregroundStyle(Theme.gold)
                                    Text(t.headline)
                                        .font(TFont.body(13, weight: .bold))
                                        .foregroundStyle(Theme.text)
                                    Text(t.body)
                                        .font(TFont.body(12.5))
                                        .foregroundStyle(Theme.muted)
                                        .lineSpacing(3)
                                    Text(t.name)
                                        .font(TFont.body(10))
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.card2)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.05)))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            Button(action: onNext) {
                Text("continue")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Theme.gold.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func avatar(_ imageName: String, offset: CGFloat) -> some View {
        Image(imageName)
            .resizable().scaledToFill()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.card2, lineWidth: 2))
            .offset(x: offset)
    }
}
