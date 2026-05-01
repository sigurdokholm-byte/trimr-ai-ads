import SwiftUI

struct OBChart: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var pathProgress: CGFloat = 0

    private let points: [(label: String, y: Double)] = [
        ("Day 1",  0.20),
        ("Day 14", 0.55),
        ("Day 30", 0.90),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 24) {
                Text("TRIMR works.")
                    .font(TFont.display(28))
                    .tracking(-0.5)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    ZStack {
                        // y-axis label
                        Text("Style confidence")
                            .labelMono()
                            .rotationEffect(.degrees(-90))
                            .position(x: 8, y: h / 2)

                        // line
                        Path { p in
                            for (i, point) in points.enumerated() {
                                let x = CGFloat(i) * (w - 40) / CGFloat(points.count - 1) + 24
                                let y = h - CGFloat(point.y) * (h - 30) - 8
                                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                else      { p.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(Theme.goldGlow, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .shadow(color: Theme.gold.opacity(0.45), radius: 10)

                        // dots + labels at end
                        ForEach(points.indices, id: \.self) { i in
                            let point = points[i]
                            let x = CGFloat(i) * (w - 40) / CGFloat(points.count - 1) + 24
                            let y = h - CGFloat(point.y) * (h - 30) - 8
                            Circle().fill(Theme.gold)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                                .opacity(pathProgress >= CGFloat(i) / CGFloat(points.count - 1) ? 1 : 0)
                            Text(point.label)
                                .font(TFont.mono(10, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                                .position(x: x, y: h - 6)
                        }
                    }
                }
                .frame(height: 180)
                .padding(20)
                .background(Color(hex: 0x1C1812))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 6) {
                    Text("90% of TRIMR users find a cut they keep within 30 days.")
                        .font(TFont.body(14, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center)
                    Text("— TRIMR INTERNAL DATA, 2026")
                        .labelMono()
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { pathProgress = 1 }
        }
    }
}
