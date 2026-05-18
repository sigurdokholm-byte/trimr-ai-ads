import SwiftUI
import UserNotifications

/// Notification opt-in (Act III). Mau-style: lowercase headline, hero bell with
/// gold glow, three short benefit rows, primary "turn on" CTA + skip text link.
/// Soft ask — never gate progression.
struct OBNotifications: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var granted: Bool?

    @State private var bellPulse: CGFloat = 0.92
    @State private var requesting: Bool = false

    private struct Benefit {
        let symbol: String
        let title: String
        let body: String
    }

    private let benefits: [Benefit] = [
        .init(symbol: "camera.viewfinder",
              title: "daily scan reminder",
              body: "one nudge a day to check your hair in."),
        .init(symbol: "flame.fill",
              title: "keep your streak",
              body: "don't break the chain — improve daily."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 0) {
                Spacer().frame(height: 18)

                bellHero

                Spacer().frame(height: 22)

                Text("notifications")
                    .labelMono(size: 11, tracking: 2.4)
                    .foregroundStyle(Theme.gold)

                Spacer().frame(height: 8)

                (
                    Text("stay ")
                        .foregroundStyle(Theme.text)
                    + Text("sharp")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.black)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
                .multilineTextAlignment(.center)

                Spacer().frame(height: 6)

                Text("one daily nudge. keep your streak alive.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)

                Spacer().frame(height: 24)

                VStack(spacing: 10) {
                    ForEach(benefits.indices, id: \.self) { i in
                        benefitRow(benefits[i])
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }

            Button(action: requestPermission) {
                Text(requesting ? "asking…" : "turn on notifications")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(requesting)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)

            Button { granted = false; onNext() } label: {
                Text("maybe later")
                    .font(TFont.body(14, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                bellPulse = 1.06
            }
        }
    }

    private var bellHero: some View {
        ZStack {
            Circle()
                .fill(Theme.gold.opacity(0.18))
                .frame(width: 138, height: 138)
                .blur(radius: 14)

            Circle()
                .stroke(Theme.gold.opacity(0.25), lineWidth: 1.5)
                .frame(width: 124, height: 124)
                .scaleEffect(bellPulse)

            Circle()
                .fill(Theme.goldGlow)
                .frame(width: 96, height: 96)
                .shadow(color: Theme.gold.opacity(0.55), radius: 24, y: 0)

            Image(systemName: "bell.fill")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(Color(hex: 0x0A0804))
        }
    }

    private func benefitRow(_ b: Benefit) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.gold.opacity(0.16))
                Image(systemName: b.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 36, height: 36)
            .overlay(Circle().stroke(Theme.gold.opacity(0.4), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(b.title)
                    .font(TFont.body(15, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text(b.body)
                    .font(TFont.body(12))
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func requestPermission() {
        guard !requesting else { return }
        requesting = true
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { ok, _ in
            DispatchQueue.main.async {
                granted = ok
                if ok { HairNotifications.scheduleDailyReminder() }
                requesting = false
                onNext()
            }
        }
    }
}
