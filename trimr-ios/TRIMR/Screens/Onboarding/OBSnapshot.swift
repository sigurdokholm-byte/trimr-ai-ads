import SwiftUI

/// Locked "snapshot ready" screen — same visual DNA as OBFreeReveal but with the
/// user's real captured photo blurred behind a gold padlock. Sits late in
/// Act III, just before the paywall, to drive the final pull.
struct OBSnapshot: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var shimmerX: CGFloat = -1.2
    @State private var glow: Double = 0.6

    private var matchName: String {
        state.analysis?.recommendation.name ?? "Your perfect cut"
    }

    private var matchMeta: String {
        let face = state.analysis?.faceShape.uppercased() ?? "ANALYZING"
        let percent = matchPercent
        return "\(percent)% MATCH · \(face)"
    }

    private var matchPercent: Int {
        switch state.analysis?.recommendation.rating {
        case 5: return 97
        case 4: return 91
        case 3: return 84
        case 2: return 76
        default: return 92
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                Text("your snapshot")
                    .labelMono(size: 11, tracking: 2.4)
                    .foregroundStyle(Theme.gold)

                Spacer().frame(height: 10)

                (
                    Text("your style snapshot is ")
                        .foregroundStyle(Theme.text)
                    + Text("ready")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.black)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.5)
                .multilineTextAlignment(.center)

                Spacer().frame(height: 28)

                snapshotCard

                Spacer().frame(height: 18)

                (
                    Text("plus ")
                        .foregroundStyle(Theme.muted)
                    + Text("2 more matches")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.semibold)
                    + Text(" inside.")
                        .foregroundStyle(Theme.muted)
                )
                .font(TFont.body(13))

                Spacer()

                Button(action: onNext) {
                    Text("reveal my snapshot")
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
            .padding(.horizontal, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                shimmerX = 1.2
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glow = 1
            }
        }
    }

    private var snapshotCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Theme.gold.opacity(0.18 * glow))
                .blur(radius: 22)
                .padding(-8)

            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(Theme.card2)

                Group {
                    if let img = state.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 32)
                    } else {
                        RadialGradient(
                            colors: [
                                Color(hex: 0x4A3320).opacity(0.55),
                                Color(hex: 0x1F1812).opacity(0.4),
                                .clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.42),
                            startRadius: 6, endRadius: 140
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(Color.black.opacity(0.32))

                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Theme.gold.opacity(0.22), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * shimmerX)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))

                VStack {
                    HStack {
                        Text("PREVIEW")
                            .font(TFont.mono(10, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(Theme.muted)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                    Spacer()

                    ZStack {
                        Circle().fill(Theme.gold.opacity(0.18))
                            .overlay(Circle().stroke(Theme.gold.opacity(0.65), lineWidth: 1.5))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Theme.gold)
                    }
                    .frame(width: 64, height: 64)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 18, y: 0)

                    Spacer()

                    VStack(spacing: 6) {
                        Text(matchName)
                            .font(TFont.display(20))
                            .tracking(-0.3)
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(matchMeta)
                            .font(TFont.mono(10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Theme.gold.opacity(0.45), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .aspectRatio(0.78, contentMode: .fit)
    }
}
