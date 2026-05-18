import SwiftUI

/// The "proof" screen. A Mau-style two-path comparison inside a card: the
/// smooth rising "with trimr" line vs the jagged "on your own" line (✗ marks +
/// rose fill where it keeps failing). The divergence IS the argument. Anchored
/// on the left to the user's own satisfaction so the start feels personal.
struct OBConfidenceChart: View {
    let satisfaction: Int?
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var drawProgress: CGFloat = 0   // 0…1 line trim
    @State private var headlineOpacity: Double = 0
    @State private var annotationsOpacity: Double = 0
    @State private var peakPulse: Bool = false
    @State private var footerOpacity: Double = 0

    /// Normalized good-line start height (fraction of h; larger = lower).
    /// Lower satisfaction → starts lower, so the rise reads as more dramatic.
    private var goodStartFrac: CGFloat {
        let s = CGFloat(satisfaction ?? 4)
        return min(max(0.92 - s / 10 * 0.28, 0.66), 0.86)
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 26)

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

                chartCard
                    .padding(.top, 24)

                Spacer()

                (
                    Text("9 in 10 men look better after the ")
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
            withAnimation(.easeInOut(duration: 1.5).delay(0.4)) { drawProgress = 1 }
            withAnimation(.easeOut(duration: 0.6).delay(1.7)) { annotationsOpacity = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(2.0)) { footerOpacity = 1 }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(2.1)) {
                peakPulse = true
            }
        }
    }

    // MARK: Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header: title + legend,
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("your looks")
                        .font(TFont.body(15, weight: .bold))
                        .foregroundStyle(Theme.text)
                    HStack(spacing: 5) {
                        Text("")
                            .font(TFont.body(11, weight: .bold))
                            .foregroundStyle(Theme.red)
                        Text("")
                            .font(TFont.body(11))
                            .foregroundStyle(Theme.muted)
                    }
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.gold.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.gold.opacity(0.22), lineWidth: 1))
                    Image(systemName: "scissors")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.gold)
                }
                .frame(width: 34, height: 34)
            }
            .padding(.bottom, 14)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let goodStart = CGPoint(x: 0, y: h * goodStartFrac)
                let goodEnd   = CGPoint(x: w, y: h * 0.10)
                let badPts    = badPoints(w: w, h: h)
                let badEnd    = badPts.last ?? .zero
                // ✗ sit on the two worst dips of the jagged path.
                let crosses   = [badPts[2], badPts[5]]

                ZStack {
                    grid(w: w, h: h)

                    // ── On-your-own (bad) path ───────────────────────────
                    badArea(badPts, w: w, h: h)
                        .fill(LinearGradient(
                            colors: [Theme.red.opacity(0.22), Theme.red.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom))
                        .opacity(Double(drawProgress))

                    badLine(badPts)
                        .trim(from: 0, to: drawProgress)
                        .stroke(Theme.red.opacity(0.75),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // ── With-trimr (good) path ───────────────────────────
                    goodArea(w: w, h: h, start: goodStart, end: goodEnd)
                        .fill(LinearGradient(
                            colors: [Theme.gold.opacity(0.20), Theme.gold.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom))
                        .opacity(Double(drawProgress))

                    // Soft glow underlay
                    goodLine(w: w, h: h, start: goodStart, end: goodEnd)
                        .trim(from: 0, to: drawProgress)
                        .stroke(Theme.gold.opacity(0.45),
                                style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .blur(radius: 8)
                    // Crisp line
                    goodLine(w: w, h: h, start: goodStart, end: goodEnd)
                        .trim(from: 0, to: drawProgress)
                        .stroke(Theme.goldGlow,
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

                    // ✗ marks on the failure path
                    ForEach(crosses.indices, id: \.self) { i in
                        Text("✕")
                            .font(TFont.body(13, weight: .bold))
                            .foregroundStyle(Theme.red)
                            .position(crosses[i])
                            .opacity(annotationsOpacity)
                    }

                    // Failure annotations
                    annotation("bad cut again", color: Theme.red.opacity(0.85))
                        .position(x: badPts[2].x, y: badPts[2].y + 20)
                        .opacity(annotationsOpacity)
                    annotation("still guessing", color: Theme.red.opacity(0.85))
                        .position(x: badPts[5].x, y: badPts[5].y + 20)
                        .opacity(annotationsOpacity)

                    // "with trimr" annotation near the rising line
                    annotation("with trimr", color: Theme.gold)
                        .position(x: w * 0.66, y: h * 0.22)
                        .opacity(annotationsOpacity)

                    // Start markers (hollow)
                    hollowDot(color: Theme.gold).position(goodStart)
                        .opacity(drawProgress > 0.02 ? 1 : 0)
                    hollowDot(color: Theme.red.opacity(0.7)).position(badPts[0])
                        .opacity(drawProgress > 0.02 ? 1 : 0)

                    // End dots
                    Circle().fill(Theme.red.opacity(0.8))
                        .frame(width: 11, height: 11)
                        .position(badEnd)
                        .opacity(drawProgress > 0.97 ? 1 : 0)

                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                colors: [Theme.gold.opacity(0.45), .clear],
                                center: .center, startRadius: 2, endRadius: 34))
                            .frame(width: 68, height: 68)
                        Circle().stroke(Theme.gold.opacity(0.35), lineWidth: 1)
                            .frame(width: 30, height: 30)
                            .scaleEffect(peakPulse ? 1.25 : 1.0)
                            .opacity(peakPulse ? 0 : 0.8)
                        Circle().fill(Theme.goldGlow)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 1))
                            .shadow(color: Theme.gold.opacity(0.8), radius: 12)
                    }
                    .position(goodEnd)
                    .opacity(drawProgress > 0.97 ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: drawProgress)
                }
            }
            .frame(height: 240)

            HStack {
                Text("month 1"); Spacer()
                Text("month 2"); Spacer()
                Text("month 3")
            }
            .font(TFont.body(11))
            .foregroundStyle(Theme.muted)
            .padding(.top, 12)
        }
        .padding(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18))
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color(hex: 0x1E1812), Theme.card2],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(RadialGradient(
                            colors: [Color.white.opacity(0.05), .clear],
                            center: .init(x: 0.5, y: -0.1),
                            startRadius: 0, endRadius: 260))
                )
                .shadow(color: .black.opacity(0.45), radius: 22, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(
                    colors: [Theme.gold.opacity(0.35), Theme.gold.opacity(0.06)],
                    startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: Paths

    /// Smooth S-rising good line.
    private func goodLine(w: CGFloat, h: CGFloat, start: CGPoint, end: CGPoint) -> Path {
        Path { p in
            p.move(to: start)
            p.addCurve(to: end,
                       control1: CGPoint(x: w * 0.40, y: start.y),
                       control2: CGPoint(x: w * 0.58, y: end.y + h * 0.30))
        }
    }

    private func goodArea(w: CGFloat, h: CGFloat, start: CGPoint, end: CGPoint) -> Path {
        var p = goodLine(w: w, h: h, start: start, end: end)
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }

    /// Jagged "on your own" path — stays low, oscillates, never recovers.
    private func badPoints(w: CGFloat, h: CGFloat) -> [CGPoint] {
        let fr: [CGFloat] = [0.86, 0.80, 0.92, 0.82, 0.90, 0.94, 0.88]
        return fr.enumerated().map { i, f in
            CGPoint(x: w * CGFloat(i) / CGFloat(fr.count - 1), y: h * f)
        }
    }

    private func badLine(_ pts: [CGPoint]) -> Path {
        Path { p in
            guard let first = pts.first else { return }
            p.move(to: first)
            for i in 1..<pts.count {
                let prev = pts[i - 1]
                let cur = pts[i]
                let midX = (prev.x + cur.x) / 2
                p.addCurve(to: cur,
                           control1: CGPoint(x: midX, y: prev.y),
                           control2: CGPoint(x: midX, y: cur.y))
            }
        }
    }

    private func badArea(_ pts: [CGPoint], w: CGFloat, h: CGFloat) -> Path {
        var p = badLine(pts)
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }

    // MARK: Pieces

    private func grid(w: CGFloat, h: CGFloat) -> some View {
        Path { p in
            for i in 1...3 {
                let y = h * CGFloat(i) / 4
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: w, y: y))
            }
        }
        .stroke(Color.white.opacity(0.045),
                style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
    }

    private func hollowDot(color: Color) -> some View {
        Circle().fill(Theme.card2)
            .overlay(Circle().stroke(color, lineWidth: 2))
            .frame(width: 13, height: 13)
    }

    private func annotation(_ text: String, color: Color) -> some View {
        Text(text)
            .font(TFont.body(10, weight: .semibold))
            .foregroundStyle(color)
            .fixedSize()
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: 0x14100B).opacity(0.85))
                    .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
            )
    }
}
