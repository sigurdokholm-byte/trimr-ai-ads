import SwiftUI

// MARK: - Primitives

struct Card<Content: View>: View {
    var padding: CGFloat = 0
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(padding)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct GoldTag: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(TFont.mono(10, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.gold.opacity(0.1))
            .overlay(Capsule().stroke(Theme.gold.opacity(0.25), lineWidth: 1))
            .clipShape(Capsule())
    }
}

struct GoldButton: View {
    let label: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: { Haptics.medium(); action() }) {
            Text(label)
                .font(TFont.display(14))
                .tracking(0.3)
                .foregroundStyle(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.goldGlow)
                .clipShape(Capsule())
                .shadow(color: Theme.gold.opacity(0.25), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let label: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: { Haptics.light(); action() }) {
            Text(label)
                .font(TFont.body(14, weight: .medium))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(Capsule().stroke(Theme.borderStrong, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen chrome

struct ScreenHeader: View {
    let title: String?
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: { Haptics.light(); onBack() }) {
                    ZStack {
                        Circle().fill(Theme.card)
                            .overlay(Circle().stroke(Theme.border))
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
            }
            if let title {
                Text(title)
                    .font(TFont.display(22))
                    .tracking(-0.4)
                    .foregroundStyle(Theme.text)
            }
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Theme.bg.opacity(0.98))
        .overlay(Rectangle().fill(Theme.border).frame(height: 0.5), alignment: .bottom)
    }
}

// MARK: - Section title helper

struct SectionTitle: View {
    let eyebrow: String?
    let title: String
    var trailing: AnyView? = nil

    init(eyebrow: String? = nil, title: String, trailing: AnyView? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let eyebrow {
                Text(eyebrow).labelMono().foregroundStyle(Theme.gold)
            }
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(TFont.display(18))
                    .tracking(-0.3)
                    .foregroundStyle(Theme.text)
                Spacer()
                if let trailing { trailing }
            }
        }
    }
}

struct LinkChip: View {
    let label: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 4) {
                Text(label).font(TFont.body(12, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .overlay(Capsule().stroke(Theme.border))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plan pill (shown in headers to surface remaining Look credits)

struct PlanPill: View {
    let looksLeft: Int?
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 8) {
                Circle().fill(Theme.gold).frame(width: 6, height: 6)
                Text(looksLeft.map { "\($0) LEFT" } ?? "FREE")
                    .font(TFont.mono(10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Theme.card)
            .overlay(Capsule().stroke(Theme.borderStrong))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Segmented pill (filter control)

struct SegmentedPill<T: Hashable>: View {
    let items: [(T, String)]
    @Binding var selection: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.0) { value, label in
                    let active = selection == value
                    Button { Haptics.selection(); selection = value } label: {
                        Text(label)
                            .font(TFont.body(12, weight: active ? .semibold : .medium))
                            .foregroundStyle(active ? Color(hex: 0x0A0804) : Theme.muted)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(active ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.card))
                            .overlay(Capsule().stroke(active ? Color.clear : Theme.border))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Tab Bar Icons

struct TabIcon: View {
    enum Kind { case home, scissors, wand, bookmark, face, person }
    let kind: Kind
    let active: Bool

    var color: Color { active ? Theme.gold : Theme.muted2 }
    var lw: CGFloat { active ? 2 : 1.6 }

    var body: some View {
        Canvas { _,_ in }
            .frame(width: 24, height: 24)
            .overlay(shape)
    }

    @ViewBuilder private var shape: some View {
        switch kind {
        case .home:
            ZStack {
                Circle()
                    .fill(active ? Theme.gold.opacity(0.15) : .clear)
                    .overlay(Circle().stroke(color, lineWidth: lw))
                    .frame(width: 20, height: 20)
                Path { p in
                    p.move(to: .init(x: 5, y: 12))
                    p.addLine(to: .init(x: 12, y: 10))
                    p.addLine(to: .init(x: 12, y: 14))
                    p.closeSubpath()
                }
                .fill(color)
                Path { p in
                    p.move(to: .init(x: 19, y: 12))
                    p.addLine(to: .init(x: 12, y: 10))
                    p.addLine(to: .init(x: 12, y: 14))
                    p.closeSubpath()
                }
                .stroke(color, style: .init(lineWidth: lw, lineJoin: .round))
                Circle()
                    .fill(color)
                    .frame(width: 2.2, height: 2.2)
            }
        case .scissors:
            ZStack {
                Circle().stroke(color, lineWidth: lw).frame(width: 6, height: 6).offset(x: -6, y: -6)
                Circle().stroke(color, lineWidth: lw).frame(width: 6, height: 6).offset(x: -6, y: 6)
                Path { p in p.move(to: .init(x: 8.5, y: 8.5)); p.addLine(to: .init(x: 19, y: 19)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
                Path { p in p.move(to: .init(x: 8.5, y: 15.5)); p.addLine(to: .init(x: 19, y: 5)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
            }
        case .wand:
            ZStack {
                Path { p in
                    p.move(to: .init(x: 9, y: 3))
                    p.addLine(to: .init(x: 10.5, y: 6.5))
                    p.addLine(to: .init(x: 14, y: 8))
                    p.addLine(to: .init(x: 10.5, y: 9.5))
                    p.addLine(to: .init(x: 9, y: 13))
                    p.addLine(to: .init(x: 7.5, y: 9.5))
                    p.addLine(to: .init(x: 4, y: 8))
                    p.addLine(to: .init(x: 7.5, y: 6.5))
                    p.closeSubpath()
                }
                .fill(active ? Theme.gold.opacity(0.15) : .clear)
                .stroke(color, lineWidth: lw)
                Path { p in
                    p.move(to: .init(x: 17, y: 12))
                    p.addLine(to: .init(x: 18.2, y: 14.8))
                    p.addLine(to: .init(x: 21, y: 16))
                    p.addLine(to: .init(x: 18.2, y: 17.2))
                    p.addLine(to: .init(x: 17, y: 20))
                    p.addLine(to: .init(x: 15.8, y: 17.2))
                    p.addLine(to: .init(x: 13, y: 16))
                    p.addLine(to: .init(x: 15.8, y: 14.8))
                    p.closeSubpath()
                }.stroke(color, lineWidth: lw)
            }
        case .bookmark:
            Path { p in
                p.move(to: .init(x: 5, y: 3))
                p.addLine(to: .init(x: 19, y: 3))
                p.addLine(to: .init(x: 20, y: 4))
                p.addLine(to: .init(x: 20, y: 21))
                p.addLine(to: .init(x: 12, y: 17))
                p.addLine(to: .init(x: 4, y: 21))
                p.addLine(to: .init(x: 4, y: 4))
                p.closeSubpath()
            }
            .fill(active ? Theme.gold.opacity(0.15) : .clear)
            .stroke(color, lineWidth: lw)
        case .face:
            ZStack {
                Path { p in p.move(to: .init(x: 3, y: 8)); p.addLine(to: .init(x: 3, y: 5)); p.addQuadCurve(to: .init(x: 5, y: 3), control: .init(x: 3, y: 3)); p.addLine(to: .init(x: 8, y: 3)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
                Path { p in p.move(to: .init(x: 21, y: 8)); p.addLine(to: .init(x: 21, y: 5)); p.addQuadCurve(to: .init(x: 19, y: 3), control: .init(x: 21, y: 3)); p.addLine(to: .init(x: 16, y: 3)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
                Path { p in p.move(to: .init(x: 3, y: 16)); p.addLine(to: .init(x: 3, y: 19)); p.addQuadCurve(to: .init(x: 5, y: 21), control: .init(x: 3, y: 21)); p.addLine(to: .init(x: 8, y: 21)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
                Path { p in p.move(to: .init(x: 21, y: 16)); p.addLine(to: .init(x: 21, y: 19)); p.addQuadCurve(to: .init(x: 19, y: 21), control: .init(x: 21, y: 21)); p.addLine(to: .init(x: 16, y: 21)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
                Circle().fill(color).frame(width: 2, height: 2).offset(x: -3, y: -2)
                Circle().fill(color).frame(width: 2, height: 2).offset(x:  3, y: -2)
                Path { p in p.move(to: .init(x: 9, y: 15)); p.addQuadCurve(to: .init(x: 15, y: 15), control: .init(x: 12, y: 17)) }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
            }
        case .person:
            ZStack {
                Circle()
                    .fill(active ? Theme.gold.opacity(0.15) : .clear)
                    .overlay(Circle().stroke(color, lineWidth: lw))
                    .frame(width: 8, height: 8)
                    .offset(y: -4)
                Path { p in
                    p.move(to: .init(x: 4, y: 20))
                    p.addQuadCurve(to: .init(x: 20, y: 20), control: .init(x: 12, y: 13))
                }.stroke(color, style: .init(lineWidth: lw, lineCap: .round))
            }
        }
    }
}

// MARK: - Analyzing checklist (shared between onboarding & in-app re-analysis)

struct AnalyzingChecklistView: View {
    @State private var statusIndex: Int = 0
    @State private var pulse: CGFloat = 0.85

    /// Checklist lines shown under the logo. Defaults to the face-analysis
    /// copy; try-on and hair-color pass their own so the steps describe the
    /// work actually happening on that screen.
    var statuses: [String] = [
        "Detecting facial landmarks…",
        "Analyzing face shape…",
        "Matching to hairstyles…",
        "Filtering by your preferences…",
        "Finding your best hairstyle",
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.gold.opacity(0.18), .clear],
                center: .center, startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Theme.gold.opacity(0.18), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulse)
                    Circle()
                        .fill(Theme.gold.opacity(0.12))
                        .overlay(Circle().stroke(Theme.gold.opacity(0.6), lineWidth: 1.5))
                        .frame(width: 140, height: 140)

                    (Text("TRIM").foregroundStyle(Theme.text) + Text("R").foregroundStyle(Theme.gold))
                        .font(TFont.display(28))
                        .tracking(3)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        pulse = 1.05
                    }
                }

                VStack(spacing: 10) {
                    ForEach(0..<statuses.count, id: \.self) { i in
                        if i <= statusIndex {
                            HStack(spacing: 8) {
                                if i < statusIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.gold)
                                } else {
                                    ProgressView().tint(Theme.gold).scaleEffect(0.7)
                                }
                                Text(statuses[i])
                                    .font(TFont.body(13, weight: .medium))
                                    .foregroundStyle(i < statusIndex ? Theme.muted : Theme.text)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .frame(height: 160, alignment: .top)
                .animation(.easeInOut(duration: 0.3), value: statusIndex)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .task {
            for i in 0..<statuses.count {
                await MainActor.run { statusIndex = i }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
            await MainActor.run { Haptics.success() }
        }
    }
}

// MARK: - Google "G" logo

/// The official multi-colour Google "G" mark, drawn from Google's published
/// 24×24 SVG path data so it stays crisp at any size and ships no asset.
/// Sub-paths are filled in Google's source order (blue, green, yellow, red).
struct GoogleGLogo: View {
    var body: some View {
        ZStack {
            SVGPathShape(Self.blue).fill(Color(hex: 0x4285F4))
            SVGPathShape(Self.green).fill(Color(hex: 0x34A853))
            SVGPathShape(Self.yellow).fill(Color(hex: 0xFBBC05))
            SVGPathShape(Self.red).fill(Color(hex: 0xEA4335))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    static let blue = "M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
    static let green = "M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
    static let yellow = "M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
    static let red = "M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
}

/// Minimal SVG `path` data → `Path`. Supports the M/L/H/V/C/S/Z commands
/// (absolute + relative) that Google's "G" mark uses; arcs/quads bail safely.
/// Coordinates are read in a `viewBox`-square space and scaled, aspect-fit
/// and centred, into the target rect.
struct SVGPathShape: Shape {
    let d: String
    let viewBox: CGFloat

    init(_ d: String, viewBox: CGFloat = 24) {
        self.d = d
        self.viewBox = viewBox
    }

    private enum Tok { case cmd(Character); case num(CGFloat) }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scale = min(rect.width, rect.height) / viewBox
        let ox = rect.minX + (rect.width  - viewBox * scale) / 2
        let oy = rect.minY + (rect.height - viewBox * scale) / 2
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: ox + x * scale, y: oy + y * scale)
        }

        let toks = Self.tokenize(d)
        var t = 0
        func num() -> CGFloat? {
            guard t < toks.count, case .num(let v) = toks[t] else { return nil }
            t += 1; return v
        }
        func nextIsNum() -> Bool {
            guard t < toks.count, case .num = toks[t] else { return false }
            return true
        }

        var cur = CGPoint.zero
        var sub = CGPoint.zero          // current sub-path start
        var ctrl: CGPoint? = nil        // last cubic control (for S/s)

        while t < toks.count {
            guard case .cmd(let first) = toks[t] else { break }
            t += 1
            var c = first
            repeat {
                switch c {
                case "M", "m":
                    guard let a = num(), let b = num() else { break }
                    cur = c == "M" ? CGPoint(x: a, y: b)
                                   : CGPoint(x: cur.x + a, y: cur.y + b)
                    sub = cur; ctrl = nil
                    p.move(to: pt(cur.x, cur.y))
                    c = c == "M" ? "L" : "l"          // extra pairs → lineto
                case "L", "l":
                    guard let a = num(), let b = num() else { break }
                    cur = c == "L" ? CGPoint(x: a, y: b)
                                   : CGPoint(x: cur.x + a, y: cur.y + b)
                    ctrl = nil
                    p.addLine(to: pt(cur.x, cur.y))
                case "H", "h":
                    guard let a = num() else { break }
                    cur.x = c == "H" ? a : cur.x + a
                    ctrl = nil
                    p.addLine(to: pt(cur.x, cur.y))
                case "V", "v":
                    guard let a = num() else { break }
                    cur.y = c == "V" ? a : cur.y + a
                    ctrl = nil
                    p.addLine(to: pt(cur.x, cur.y))
                case "C", "c":
                    guard let a = num(), let b = num(), let e = num(),
                          let f = num(), let g = num(), let h = num() else { break }
                    let rel = c == "c"
                    let c1 = rel ? CGPoint(x: cur.x + a, y: cur.y + b) : CGPoint(x: a, y: b)
                    let c2 = rel ? CGPoint(x: cur.x + e, y: cur.y + f) : CGPoint(x: e, y: f)
                    let end = rel ? CGPoint(x: cur.x + g, y: cur.y + h) : CGPoint(x: g, y: h)
                    p.addCurve(to: pt(end.x, end.y),
                               control1: pt(c1.x, c1.y), control2: pt(c2.x, c2.y))
                    cur = end; ctrl = c2
                case "S", "s":
                    guard let e = num(), let f = num(),
                          let g = num(), let h = num() else { break }
                    let rel = c == "s"
                    let c1 = ctrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                    let c2 = rel ? CGPoint(x: cur.x + e, y: cur.y + f) : CGPoint(x: e, y: f)
                    let end = rel ? CGPoint(x: cur.x + g, y: cur.y + h) : CGPoint(x: g, y: h)
                    p.addCurve(to: pt(end.x, end.y),
                               control1: pt(c1.x, c1.y), control2: pt(c2.x, c2.y))
                    cur = end; ctrl = c2
                case "Z", "z":
                    p.closeSubpath(); cur = sub; ctrl = nil
                default:
                    return p                              // unsupported → stop
                }
            } while nextIsNum() && c != "Z" && c != "z"
        }
        return p
    }

    private static func tokenize(_ s: String) -> [Tok] {
        let cmds = Set("MmLlHhVvCcSsZzAaQqTt")
        var out: [Tok] = []
        let ch = Array(s)
        var i = 0
        while i < ch.count {
            let c = ch[i]
            if c == " " || c == "," || c == "\n" || c == "\t" || c == "\r" {
                i += 1; continue
            }
            if cmds.contains(c) { out.append(.cmd(c)); i += 1; continue }
            var j = i
            if ch[j] == "+" || ch[j] == "-" { j += 1 }
            var dot = false
            while j < ch.count {
                let g = ch[j]
                if g >= "0" && g <= "9" { j += 1 }
                else if g == "." && !dot { dot = true; j += 1 }
                else if g == "e" || g == "E" {
                    j += 1
                    if j < ch.count && (ch[j] == "+" || ch[j] == "-") { j += 1 }
                } else { break }
            }
            if j > i, let v = Double(String(ch[i..<j])) {
                out.append(.num(CGFloat(v)))
                i = j
            } else {
                i += 1                                    // skip stray char
            }
        }
        return out
    }
}
