import SwiftUI
import UIKit

/// Locked match-preview screen — shown right after `OBAnalyzing` for free users.
/// No backend analysis runs during onboarding (deferred to OBFullReveal post-
/// purchase), so this screen does NOT claim a specific match name or face shape.
/// Instead it uses the user's blurred uploaded photo as the centerpiece — that
/// IS the personalization at this stage.
struct OBFreeReveal: View {
    let name: String
    let analysis: AnalyzeResponse?
    let userImage: UIImage?
    let onContinue: () -> Void

    @State private var contentOpacity: Double = 0
    @State private var shimmerX: CGFloat = -1.2

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.gold.opacity(0.16), .clear],
                center: .top, startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                (
                    Text("your top cut is ")
                        .foregroundStyle(Theme.text)
                    + Text("ready")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.black)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
                .multilineTextAlignment(.center)

                Spacer().frame(height: 28)

                lockedCard
                    .padding(.horizontal, 48)

                Spacer().frame(height: 22)

                Text("unlock to see your top cut.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)

                Spacer()

                Button(action: onContinue) {
                    Text("reveal my look")
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
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { contentOpacity = 1 }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                shimmerX = 1.2
            }
        }
    }

    private var lockedCard: some View {
        // Rigid 3:4 portrait frame — the aspect ratio of an iPhone selfie.
        // The base shape drives the card's size; the blurred photo, shimmer
        // sweep and lock badge all sit on top as `.overlay`s, and an overlay
        // can never enlarge its parent. The card is therefore an identical
        // shape on every device and for any photo (a `scaledToFill` image
        // can no longer stretch it tall), so the "reveal my look" button
        // below always lands in the same place.
        RoundedRectangle(cornerRadius: 22)
            .fill(Theme.card2)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                Group {
                    if let img = userImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 32)
                    } else {
                        RadialGradient(
                            colors: [
                                Color(hex: 0x4A3320).opacity(0.55),
                                Color(hex: 0x261C13).opacity(0.45),
                                Color(hex: 0x120E09)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.42),
                            startRadius: 8, endRadius: 220
                        )
                    }
                }
                .overlay(Color.black.opacity(0.32))
            }
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Theme.gold.opacity(0.22), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * shimmerX)
                }
            }
            // Clip the photo + shimmer to the rounded frame.
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.18))
                        .overlay(Circle().stroke(Theme.gold.opacity(0.65), lineWidth: 1.5))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.gold)
                }
                .frame(width: 72, height: 72)
                .shadow(color: Theme.gold.opacity(0.5), radius: 18, y: 0)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Theme.gold.opacity(0.45), lineWidth: 1.2)
            )
            .background(
                // Soft gold glow — drawn behind, never affects layout size.
                RoundedRectangle(cornerRadius: 22)
                    .fill(Theme.gold.opacity(0.18))
                    .blur(radius: 22)
                    .padding(-8)
            )
    }
}
