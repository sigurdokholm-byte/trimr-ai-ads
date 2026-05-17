import SwiftUI

struct OBBlurredReveal: View {
    let name: String
    let analysis: AnalyzeResponse
    let onUnlock: () -> Void

    private var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "you" : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Your perfect cut\nis ready, \(displayName)")
                            .font(TFont.display(28))
                            .tracking(-0.5)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.text)
                        Text("Unlock to see your match")
                            .font(TFont.body(14))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.top, 56)
                    .padding(.horizontal, 24)

                    blurredCard(item: analysis.recommendation)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                .padding(.bottom, 16)
            }

            Button(action: onUnlock) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill").font(.system(size: 14, weight: .semibold))
                    Text("Reveal My Look")
                        .font(TFont.body(16, weight: .semibold))
                }
                .foregroundStyle(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Theme.goldGlow).clipShape(Capsule())
                .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func blurredCard(item: AnalyzeResponse.Recommendation) -> some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let url = item.generatedImage, let u = URL(string: url) {
                    AsyncImage(url: u) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                        } else {
                            Theme.card2
                        }
                    }
                } else {
                    Theme.card2
                }
            }
            .frame(maxWidth: .infinity).frame(height: 320)
            .clipped()
            .blur(radius: 28)
            .overlay(Rectangle().fill(Color.black.opacity(0.35)))

            HStack(spacing: 8) {
                Text("YOUR MATCH")
                    .font(TFont.mono(10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.black.opacity(0.6))
                    .overlay(Capsule().stroke(Theme.gold.opacity(0.4)))
                    .clipShape(Capsule())
            }
            .padding(14)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .padding(14)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06)))
    }
}
