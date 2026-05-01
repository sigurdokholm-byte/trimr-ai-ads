import SwiftUI

/// Day-1 celebration screen. Triggers `SKStoreReviewController.requestReview`
/// 1.2s after appear (one-shot, gated by local @State so back-nav can't re-fire).
/// Apple silently caps to ~3 prompts/user/year regardless.
struct OBDay1: View {
    let name: String
    let onContinue: () -> Void

    @State private var checkScale: CGFloat = 0.4
    @State private var checkOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var streakScale: CGFloat = 0.85
    @State private var contentOpacity: Double = 0
    @State private var pulseRing: CGFloat = 0.85
    @State private var reviewFired: Bool = false

    private var subtitle: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty
            ? "of your style journey"
            : "of your style journey, \(trimmed.lowercased())"
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.gold.opacity(0.22), .clear],
                center: .center, startRadius: 0, endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Theme.gold.opacity(0.25), lineWidth: 2)
                        .frame(width: 144, height: 144)
                        .scaleEffect(pulseRing)
                    Circle()
                        .fill(Theme.goldGlow)
                        .frame(width: 116, height: 116)
                        .shadow(color: Theme.gold.opacity(0.55), radius: 28, y: 0)
                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(Color(hex: 0x0A0804))
                }
                .scaleEffect(checkScale)
                .opacity(checkOpacity)

                Spacer().frame(height: 32)

                Text("day 1")
                    .font(TFont.display(64))
                    .tracking(-1.2)
                    .foregroundStyle(Theme.goldGlow)
                    .shadow(color: Theme.gold.opacity(0.4), radius: 18, y: 0)
                    .opacity(titleOpacity)

                Spacer().frame(height: 10)

                Text(subtitle)
                    .font(TFont.body(13, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .opacity(titleOpacity)

                Spacer().frame(height: 28)

                HStack(spacing: 8) {
                    Text("🔥").font(.system(size: 18))
                    Text("streak started")
                        .font(TFont.body(14, weight: .bold))
                        .foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(Theme.card)
                .overlay(Capsule().stroke(Theme.gold.opacity(0.45), lineWidth: 1))
                .clipShape(Capsule())
                .shadow(color: Theme.gold.opacity(0.18), radius: 14, y: 0)
                .scaleEffect(streakScale)
                .opacity(contentOpacity)

                Spacer().frame(height: 32)

                (
                    Text("you ")
                        .foregroundStyle(Theme.muted)
                    + Text("showed up")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.semibold)
                    + Text(". the hardest part of any change.")
                        .foregroundStyle(Theme.muted)
                )
                .font(TFont.body(14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(contentOpacity)

                Spacer()

                Button(action: onContinue) {
                    Text("keep going")
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
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                checkScale = 1
                checkOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
                titleOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
                streakScale = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                contentOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseRing = 1.05
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled, !reviewFired {
                reviewFired = true
                StoreKitManager.requestReviewIfAvailable()
            }
        }
    }
}
