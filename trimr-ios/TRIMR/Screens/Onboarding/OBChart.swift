import SwiftUI

/// Confidence-curve screen — Mau-style: lowercase headline, large card with
/// stylized chart inside, conversational caption beneath. The card mirrors
/// Mau's white-on-orange layout but inverted to dark/gold for TRIMR.
struct OBChart: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var pathProgress: CGFloat = 0

    private let points: [(label: String, y: Double)] = [
        ("week 1", 0.18),
        ("week 2", 0.52),
        ("week 4", 0.88),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 22) {
                Spacer().frame(height: 28)

                (
                    Text("trimr ")
                        .foregroundStyle(Theme.text)
                    + Text("works")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.black)
                    + Text(".")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.display(32))
                .tracking(-0.5)

                // Card with chart
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("style confidence")
                            .font(TFont.body(14, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        HStack(spacing: 5) {
                            Circle().fill(Theme.gold).frame(width: 7, height: 7)
                            Text("you")
                                .font(TFont.mono(10, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                        }
                    }

                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        ZStack {
                            // gridline
                            VStack(spacing: 0) {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(height: 1)
                                    Spacer()
                                }
                                Rectangle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(height: 1)
                            }

                            // shaded area under curve
                            Path { p in
                                for (i, point) in points.enumerated() {
                                    let x = CGFloat(i) * (w - 16) / CGFloat(points.count - 1) + 8
                                    let y = h - CGFloat(point.y) * (h - 24) - 18
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else      { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                                p.addLine(to: CGPoint(x: w - 8, y: h - 18))
                                p.addLine(to: CGPoint(x: 8, y: h - 18))
                                p.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [Theme.gold.opacity(0.32), Theme.gold.opacity(0.0)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .opacity(Double(pathProgress))

                            // line
                            Path { p in
                                for (i, point) in points.enumerated() {
                                    let x = CGFloat(i) * (w - 16) / CGFloat(points.count - 1) + 8
                                    let y = h - CGFloat(point.y) * (h - 24) - 18
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else      { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .trim(from: 0, to: pathProgress)
                            .stroke(Theme.goldGlow,
                                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                            .shadow(color: Theme.gold.opacity(0.5), radius: 10)

                            // dots
                            ForEach(points.indices, id: \.self) { i in
                                let point = points[i]
                                let x = CGFloat(i) * (w - 16) / CGFloat(points.count - 1) + 8
                                let y = h - CGFloat(point.y) * (h - 24) - 18
                                Circle()
                                    .fill(Theme.gold)
                                    .frame(width: 9, height: 9)
                                    .overlay(Circle().stroke(Color(hex: 0x0A0804), lineWidth: 2))
                                    .position(x: x, y: y)
                                    .opacity(pathProgress >= CGFloat(i) / CGFloat(points.count - 1) ? 1 : 0)
                            }

                            // x-axis labels
                            HStack(spacing: 0) {
                                ForEach(points.indices, id: \.self) { i in
                                    Text(points[i].label)
                                        .font(TFont.mono(10, weight: .semibold))
                                        .foregroundStyle(Theme.muted)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .position(x: w / 2, y: h - 6)
                        }
                    }
                    .frame(height: 160)
                }
                .padding(18)
                .background(Theme.card2)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.gold.opacity(0.18), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))

                (
                    Text("9 in 10 men find a cut they ")
                        .foregroundStyle(Theme.text)
                    + Text("keep")
                        .foregroundStyle(Theme.gold)
                        .fontWeight(.bold)
                    + Text(" within 30 days.")
                        .foregroundStyle(Theme.text)
                )
                .font(TFont.body(15))
                .multilineTextAlignment(.leading)
                .lineSpacing(3)

                Text("— trimr internal data, 2026")
                    .font(TFont.mono(10, weight: .medium))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("next")
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
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) { pathProgress = 1 }
        }
    }
}
