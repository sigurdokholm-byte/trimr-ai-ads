import SwiftUI

/// The "proof" screen. A hand-built confidence curve that draws on with a
/// trim animation, anchored on the left to the user's own satisfaction score
/// so it feels personal, rising to a glowing "with trimr" peak. Closes Act I
/// with visual + clinical confirmation right before the photo climax.
struct OBConfidenceChart: View {
    let satisfaction: Int?
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var drawProgress: CGFloat = 0   // 0…1 curve trim
    @State private var headlineOpacity: Double = 0
    @State private var peakPulse: Bool = false
    @State private var footerOpacity: Double = 0

    /// Normalized start height (0 = bottom, 1 = top). Lower satisfaction → a
    /// lower, more dramatic starting point. Clamped so the curve always rises.
    private var startY: CGFloat {
        let s = CGFloat(satisfaction ?? 4)
        return min(max(s / 10 * 0.45, 0.08), 0.42)
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 30)

                (
                    Text("this is what the ")
                        .foregroundStyle(Theme.text)
                    + Text("right cut")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.black)
                    + Text(" does.")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(30))
                .tracking(-0.6)
                .opacity(headlineOpacity)

                Text("confidence with your hair")
                    .font(TFont.body(14))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 8)
                    .opacity(headlineOpacity)

                chartCard
                    .padding(.top, 28)

                Spacer()

                (
                    Text("9 in 10 men feel more confident after the ")
                        .foregroundStyle(Theme.muted)
                    + Text("right cut")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.bold)
                    + Text(".")
                        .foregroundStyle(Theme.muted)
                )
                .font(TFont.body(14))
                .lineSpacing(3)
                .opacity(footerOpacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Button(action: onNext) {
                Text("i'm in")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 32)
            .opacity(footerOpacity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { headlineOpacity = 1 }
            withAnimation(.easeInOut(duration: 1.25).delay(0.45)) { drawProgress = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(1.75)) { footerOpacity = 1 }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(1.8)) {
                peakPulse = true
            }
        }
    }

    private var chartCard: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let startPt = CGPoint(x: 0, y: h * (1 - startY))
                let endPt   = CGPoint(x: w, y: h * 0.12)

                ZStack {
                    grid(w: w, h: h)

                    // Gradient area fill under the curve
                    curvePath(w: w, h: h, start: startPt, end: endPt, closed: true)
                        .fill(
                            LinearGradient(
                                colors: [Theme.gold.opacity(0.28), Theme.gold.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .mask(
                            curvePath(w: w, h: h, start: startPt, end: endPt, closed: true)
                                .trim(from: 0, to: drawProgress)
                                .fill()
                        )

                    // The line itself, glowing, trim-animated
                    curvePath(w: w, h: h, start: startPt, end: endPt, closed: false)
                        .trim(from: 0, to: drawProgress)
                        .stroke(
                            Theme.goldGlow,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .shadow(color: Theme.gold.opacity(0.55), radius: 10, y: 0)

                    // "now" marker (start)
                    marker(at: startPt, label: "now", filled: false)
                        .opacity(drawProgress > 0.02 ? 1 : 0)

                    // "with trimr" marker (peak), pulses
                    marker(at: endPt, label: "with trimr", filled: true)
                        .scaleEffect(peakPulse ? 1.08 : 1.0)
                        .opacity(drawProgress > 0.97 ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: drawProgress)
                }
            }
            .frame(height: 230)

            HStack {
                Text("today")
                Spacer()
                Text("week 4")
                Spacer()
                Text("month 3")
            }
            .font(TFont.body(11))
            .foregroundStyle(Theme.muted)
            .padding(.top, 12)
        }
        .padding(EdgeInsets(top: 22, leading: 18, bottom: 18, trailing: 18))
        .background(Theme.card2)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Theme.gold.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    /// Smooth rising curve from start to end using two control points.
    private func curvePath(w: CGFloat, h: CGFloat, start: CGPoint, end: CGPoint, closed: Bool) -> Path {
        Path { p in
            p.move(to: start)
            p.addCurve(
                to: end,
                control1: CGPoint(x: w * 0.42, y: start.y),
                control2: CGPoint(x: w * 0.55, y: end.y + h * 0.22)
            )
            if closed {
                p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: 0, y: h))
                p.closeSubpath()
            }
        }
    }

    private func grid(w: CGFloat, h: CGFloat) -> some View {
        Path { p in
            for i in 1...3 {
                let y = h * CGFloat(i) / 4
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: w, y: y))
            }
        }
        .stroke(Color.white.opacity(0.05), lineWidth: 1)
    }

    private func marker(at pt: CGPoint, label: String, filled: Bool) -> some View {
        ZStack {
            if filled {
                Circle().fill(Theme.gold)
                    .frame(width: 16, height: 16)
                    .shadow(color: Theme.gold.opacity(0.7), radius: 10)
            } else {
                Circle().fill(Theme.card2)
                    .overlay(Circle().stroke(Theme.gold, lineWidth: 2))
                    .frame(width: 14, height: 14)
            }
            Text(label)
                .font(TFont.body(11, weight: .semibold))
                .foregroundStyle(filled ? Theme.gold : Theme.muted)
                .fixedSize()
                .offset(y: filled ? -22 : 22)
        }
        .position(pt)
    }
}
