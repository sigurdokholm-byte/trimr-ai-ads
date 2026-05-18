import SwiftUI
import Charts
import UserNotifications

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

// MARK: - Plan pill (shown in headers to surface plan/credit state)

struct PlanPill: View {
    let isPro: Bool
    let looksLeft: Int?
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 8) {
                if isPro {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x0A0804))
                    Text("PRO")
                        .font(TFont.mono(10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: 0x0A0804))
                } else {
                    Circle().fill(Theme.gold).frame(width: 6, height: 6)
                    Text(looksLeft.map { "\($0) LEFT" } ?? "FREE")
                        .font(TFont.mono(10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.text)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isPro ? AnyShapeStyle(Theme.goldGlow) : AnyShapeStyle(Theme.card))
            .overlay(Capsule().stroke(isPro ? Color.clear : Theme.borderStrong))
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

    private let statuses = [
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

// MARK: - Subscription Paywall (daily-habit pivot, RC-authoritative)

/// The app's subscription paywall, backed by the RevenueCat Offering
/// (`$rc_weekly` / `$rc_annual`). Drop-in signature matches `OBPaywall`
/// (`name / onClose / onPurchased`) so it slots into the onboarding funnel and
/// the pushed `.pricing` screen unchanged. Purchases go through
/// `RevenueCatManager` (RC-authoritative); the `revenuecat-webhook` edge fn
/// mirrors the entitlement into `profiles.subscription_tier` for server gating.
/// `paywallState == .unavailable` shows a non-blocking fallback so a store
/// outage can never dead-end onboarding.
struct SubscriptionPaywall: View {
    let name: String
    let onClose: () -> Void
    let onPurchased: () -> Void

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var rc: RevenueCatManager
    @State private var selected: RevenueCatManager.Plan = .yearly
    @State private var showTerms = false
    @State private var showPrivacy = false

    private let benefits = [
        "Daily AI hair scan — scored 0–100",
        "A personalized routine that adapts to you",
        "Track your progress, streak & trend",
        "Unlimited try-ons & cut recommendations",
    ]

    private var yearlyPrice: String { rc.priceString(for: .yearly) ?? "$39.99" }
    private var weeklyPrice: String { rc.priceString(for: .weekly) ?? "$6.99" }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if rc.paywallState == .unavailable {
                unavailable
            } else {
                paywall
            }
        }
        .task { await rc.loadOffering() }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsOfServiceView()
                    .navigationTitle("Terms of Service").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showTerms = false }.foregroundStyle(Theme.gold) } }
            }.presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                PrivacyPolicyView()
                    .navigationTitle("Privacy Policy").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showPrivacy = false }.foregroundStyle(Theme.gold) } }
            }.presentationDragIndicator(.visible)
        }
    }

    // MARK: Main paywall

    private var paywall: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.text.opacity(0.7))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.06)).clipShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Text(name.isEmpty ? "Level up your hair\nevery single day" : "\(name), level up your\nhair every single day")
                            .font(TFont.display(30)).tracking(-0.6)
                            .multilineTextAlignment(.center).foregroundStyle(Theme.text)
                        Text("TRIMR scores your hair daily, builds your routine,\nand tracks it getting better.")
                            .font(TFont.body(13.5)).foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center).lineSpacing(3)
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(benefits, id: \.self) { line in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.gold)
                                Text(line).font(TFont.body(13.5)).foregroundStyle(Theme.text)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        planCard(.yearly, title: "Yearly", price: yearlyPrice, period: "/year",
                                 sub: "3 days free, then \(yearlyPrice)/yr", badge: "BEST VALUE")
                        planCard(.weekly, title: "Weekly", price: weeklyPrice, period: "/week",
                                 sub: "3 days free, then \(weeklyPrice)/wk", badge: nil)
                    }
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 10) {
                Button {
                    Task { await purchase() }
                } label: {
                    HStack {
                        if rc.isPurchasing { ProgressView().tint(Color(hex: 0x0A0804)) }
                        Text(rc.isPurchasing ? "Processing…" : "Start 3-Day Free Trial")
                            .font(TFont.body(16, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0A0804))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow).clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(rc.isPurchasing || rc.paywallState != .ready)

                Text("3 days free, then \(selected == .yearly ? "\(yearlyPrice)/year" : "\(weeklyPrice)/week"). Cancel anytime.")
                    .font(TFont.body(10.5)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)

                HStack(spacing: 18) {
                    Button("Terms") { showTerms = true }
                    Text("·").foregroundStyle(Theme.muted.opacity(0.5))
                    Button("Privacy Policy") { showPrivacy = true }
                    Text("·").foregroundStyle(Theme.muted.opacity(0.5))
                    Button("Restore") { Task { await restore() } }
                }
                .font(TFont.body(11.5)).foregroundStyle(Theme.muted)

                if let err = rc.purchaseError {
                    Text(err).font(TFont.body(11)).foregroundStyle(Theme.red)
                        .multilineTextAlignment(.center).padding(.top, 2)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
    }

    private func planCard(_ plan: RevenueCatManager.Plan, title: String, price: String,
                          period: String, sub: String, badge: String?) -> some View {
        let isSelected = selected == plan
        return Button { selected = plan } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20)).foregroundStyle(isSelected ? Theme.gold : Theme.muted)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title).font(TFont.display(17)).foregroundStyle(Theme.text)
                        if let badge {
                            Text(badge).font(TFont.mono(8.5, weight: .bold)).tracking(1.2)
                                .foregroundStyle(Color(hex: 0x0A0804))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Theme.gold).clipShape(Capsule())
                        }
                    }
                    Text(sub).font(TFont.body(11.5)).foregroundStyle(Theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price).font(TFont.display(18)).tracking(-0.3).foregroundStyle(Theme.text)
                    Text(period).font(TFont.body(10)).foregroundStyle(Theme.muted)
                }
            }
            .padding(18)
            .background(isSelected ? Theme.gold.opacity(0.08) : Theme.card2)
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Theme.gold : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: Fallback (store unavailable — never dead-end onboarding)

    private var unavailable: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 38)).foregroundStyle(Theme.gold)
            Text("Store unavailable")
                .font(TFont.display(22)).foregroundStyle(Theme.text)
            Text("We couldn't reach the App Store. Check your\nconnection and try again.")
                .font(TFont.body(13)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).lineSpacing(3)
            Spacer()
            Button {
                Task { await rc.loadOffering() }
            } label: {
                Text("Try Again").font(TFont.body(16, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button("Continue") { onClose() }
                .font(TFont.body(13)).foregroundStyle(Theme.muted)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 28).padding(.bottom, 32)
    }

    // MARK: Actions

    private func purchase() async {
        let ok = await rc.purchase(plan: selected)
        if ok {
            await rc.refresh()
            await app.profile.refresh()
            onPurchased()
        }
    }

    private func restore() async {
        let ok = await rc.restorePurchases()
        if ok && rc.isProEntitlementActive {
            await app.profile.refresh()
            onPurchased()
        }
    }
}

// MARK: - Daily Hair Scan (daily-habit pivot)

/// Today's hair scan: capture a selfie → `daily-hair-scan` → animated score
/// reveal (overall ring + delta vs yesterday + sub-score bars + tips).
/// Subscription-gated: non-Pro users are routed to the paywall (the edge fn
/// also enforces this server-side and returns `subscription_required`).
struct DailyScanView: View {
    var onDone: () -> Void = {}

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var rc: RevenueCatManager
    @EnvironmentObject private var photoStore: TryOnPhotoStore

    enum Phase: Equatable { case intro, scanning, result, error }
    @State private var phase: Phase = .intro
    @State private var result: DailyScanResponse?
    @State private var errorMessage = ""
    @State private var showUploadSheet = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch phase {
            case .intro:    intro
            case .scanning: scanning
            case .result:   resultView
            case .error:    errorView
            }
        }
        .fullScreenCover(isPresented: $showUploadSheet) {
            PreviewUploadSheet(
                title: "Daily Scan",
                itemName: nil, swatchHex: nil, thumbnailAsset: nil, thumbnailUIImage: nil,
                headline: "Today's hair check-in",
                subtitle: "A quick front-facing selfie in good light — we'll score it and track your progress.",
                isGenerating: false,
                canAfford: true,
                generateCostLabel: "Scan my hair",
                onGenerate: { cropped in
                    showUploadSheet = false
                    run(image: cropped)
                },
                onClose: { showUploadSheet = false },
                onTopUp: { showUploadSheet = false; app.push(.pricing) }
            )
            .environmentObject(photoStore)
        }
    }

    // MARK: Intro

    private var intro: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().stroke(Theme.gold.opacity(0.18), lineWidth: 2).frame(width: 132, height: 132)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48, weight: .light)).foregroundStyle(Theme.gold)
            }
            VStack(spacing: 10) {
                Text("Scan your hair").font(TFont.display(28)).tracking(-0.6).foregroundStyle(Theme.text)
                Text("Get today's score, see your progress,\nand keep your streak alive.")
                    .font(TFont.body(14)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            Spacer()
            Button {
                if rc.isProEntitlementActive { showUploadSheet = true }
                else { app.push(.pricing) }
            } label: {
                Text("Start Today's Scan")
                    .font(TFont.body(16, weight: .bold)).foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.goldGlow).clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28).padding(.bottom, 32)
    }

    // MARK: Scanning

    private var scanning: some View {
        VStack(spacing: 20) {
            ProgressView().tint(Theme.gold).scaleEffect(1.4)
            Text("Reading your hair…").font(TFont.body(14)).foregroundStyle(Theme.muted)
        }
    }

    // MARK: Result

    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if let r = result {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 14)
                            .frame(width: 184, height: 184)
                        Circle().trim(from: 0, to: ringProgress)
                            .stroke(Theme.goldGlow, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 184, height: 184).rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(r.overall)").font(TFont.display(56)).foregroundStyle(Theme.text)
                            Text("/ 100").font(TFont.body(12)).foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(.top, 16)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.0)) { ringProgress = CGFloat(r.overall) / 100 }
                    }

                    deltaPill(r.delta)

                    Text(r.headline)
                        .font(TFont.display(20)).tracking(-0.3).foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center).padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        subBar("Health", r.subScores.health)
                        subBar("Shape", r.subScores.shape)
                        subBar("Styling", r.subScores.styling)
                        subBar("Volume", r.subScores.volume)
                        subBar("Grooming", r.subScores.grooming)
                    }
                    .padding(18)
                    .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 18))

                    if !r.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DO THIS NEXT").font(TFont.mono(10, weight: .bold))
                                .tracking(1.6).foregroundStyle(Theme.gold)
                            ForEach(r.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 14)).foregroundStyle(Theme.gold)
                                        .padding(.top, 1)
                                    Text(tip).font(TFont.body(13)).foregroundStyle(Theme.text)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Button {
                        onDone()
                    } label: {
                        Text("Done").font(TFont.body(16, weight: .bold))
                            .foregroundStyle(Color(hex: 0x0A0804))
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(Theme.goldGlow).clipShape(Capsule())
                    }
                    .buttonStyle(.plain).padding(.top, 4)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }

    private func deltaPill(_ delta: Int?) -> some View {
        Group {
            if let d = delta {
                let up = d >= 0
                Text("\(up ? "▲ +" : "▼ ")\(d) vs last scan")
                    .font(TFont.mono(11, weight: .bold))
                    .foregroundStyle(up ? Theme.gold : Theme.red)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background((up ? Theme.gold : Theme.red).opacity(0.12))
                    .clipShape(Capsule())
            } else {
                Text("FIRST SCAN").font(TFont.mono(10, weight: .bold)).tracking(1.4)
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.white.opacity(0.06)).clipShape(Capsule())
            }
        }
    }

    private func subBar(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 12) {
            Text(label).font(TFont.body(12)).foregroundStyle(Theme.muted)
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06)).frame(height: 8)
                    Capsule().fill(Theme.goldGlow)
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(value)").font(TFont.mono(12, weight: .semibold))
                .foregroundStyle(Theme.text).frame(width: 28, alignment: .trailing)
        }
    }

    // MARK: Error

    private var errorView: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38)).foregroundStyle(Theme.red)
            Text("Scan failed").font(TFont.display(20)).foregroundStyle(Theme.text)
            Text(errorMessage.isEmpty ? "Something went wrong. Please try again." : errorMessage)
                .font(TFont.body(13)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Button {
                phase = .intro
            } label: {
                Text("Try Again").font(TFont.body(14, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Theme.goldGlow).clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
    }

    // MARK: Run

    private func run(image: UIImage) {
        withAnimation { phase = .scanning }
        Task {
            let encodingTask = Task.detached(priority: .userInitiated) { image.base64DataURL() }
            guard await FaceValidator.hasFace(in: image) else {
                encodingTask.cancel()
                errorMessage = "We couldn't find a face. Try a clear, front-facing selfie in good light."
                withAnimation { phase = .error }
                return
            }
            guard let base64 = await encodingTask.value else {
                errorMessage = "Couldn't read that photo. Try another one."
                withAnimation { phase = .error }
                return
            }
            do {
                let r = try await app.runDailyScan(imageBase64: base64)
                self.result = r
                self.ringProgress = 0
                withAnimation { phase = .result }
            } catch {
                let ns = error as NSError
                if (ns.userInfo["code"] as? String) == "subscription_required" {
                    withAnimation { phase = .intro }
                    app.push(.pricing)
                    return
                }
                errorMessage = ns.localizedDescription
                withAnimation { phase = .error }
            }
        }
    }
}

// MARK: - Daily Routine (daily-habit pivot)

/// Today's adaptive routine + streak/adherence. Steps come from the active
/// `hair_routines` row; completion is tracked per-day in `daily_checkins`.
/// Subscription-gated (generate-hair-routine enforces it server-side too).
struct RoutineView: View {
    var onOpenScan: () -> Void = {}

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var rc: RevenueCatManager

    @State private var routine: HairRoutineRow?
    @State private var completedToday: Set<String> = []
    @State private var checkins: [DailyCheckinRow] = []
    @State private var loading = true
    @State private var generating = false

    private let order: [String] = ["morning", "evening", "weekly"]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if loading {
                ProgressView().tint(Theme.gold)
            } else if let routine {
                content(routine)
            } else {
                empty
            }
        }
        .task { await load() }
    }

    // MARK: Load

    private func load() async {
        loading = true
        let r = await app.fetchActiveRoutine()
        let cs = await app.fetchRecentCheckins()
        routine = r
        checkins = cs
        completedToday = Set(cs.first(where: { $0.checkinDate == AppState.todayUTC })?.completedStepIds ?? [])
        loading = false
    }

    // MARK: Empty state

    private var empty: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 44, weight: .light)).foregroundStyle(Theme.gold)
            Text("Your routine, built for you")
                .font(TFont.display(24)).tracking(-0.5).foregroundStyle(Theme.text)
            Text("A daily plan tuned to your hair type, goals\nand your latest scan.")
                .font(TFont.body(14)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).lineSpacing(4)
            Spacer()
            Button {
                Task { await generate() }
            } label: {
                HStack {
                    if generating { ProgressView().tint(Color(hex: 0x0A0804)) }
                    Text(generating ? "Building…" : "Build my routine")
                        .font(TFont.body(16, weight: .bold)).foregroundStyle(Color(hex: 0x0A0804))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Theme.goldGlow).clipShape(Capsule())
            }
            .buttonStyle(.plain).disabled(generating)
        }
        .padding(.horizontal, 28).padding(.bottom, 32)
    }

    private func generate() async {
        guard rc.isProEntitlementActive else { app.push(.pricing); return }
        generating = true
        defer { generating = false }
        do {
            _ = try await app.generateHairRoutine()
            await load()
        } catch {
            let ns = error as NSError
            if (ns.userInfo["code"] as? String) == "subscription_required" { app.push(.pricing) }
        }
    }

    // MARK: Content

    private func content(_ r: HairRoutineRow) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerCard(r)
                ForEach(order, id: \.self) { slot in
                    let steps = r.steps.filter { $0.timeOfDay == slot }
                    if !steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(slot.uppercased())
                                .font(TFont.mono(10, weight: .bold)).tracking(1.8)
                                .foregroundStyle(Theme.gold)
                            ForEach(steps) { step in stepRow(step) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 40)
        }
    }

    private func headerCard(_ r: HairRoutineRow) -> some View {
        let dailySteps = r.steps.filter { $0.frequency == "daily" }
        let doneCount = dailySteps.filter { completedToday.contains($0.id) }.count
        let ratio = dailySteps.isEmpty ? 0 : CGFloat(doneCount) / CGFloat(dailySteps.count)
        return VStack(spacing: 16) {
            HStack(spacing: 18) {
                VStack(spacing: 2) {
                    Text("🔥 \(currentStreak())").font(TFont.display(26)).foregroundStyle(Theme.text)
                    Text("DAY STREAK").font(TFont.mono(9, weight: .bold)).tracking(1.4)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Color.white.opacity(0.07), lineWidth: 8).frame(width: 64, height: 64)
                    Circle().trim(from: 0, to: ratio)
                        .stroke(Theme.goldGlow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 64, height: 64).rotationEffect(.degrees(-90))
                    Text("\(doneCount)/\(dailySteps.count)")
                        .font(TFont.mono(12, weight: .bold)).foregroundStyle(Theme.text)
                }
            }
            if let s = r.summary, !s.isEmpty {
                Text(s).font(TFont.body(12.5)).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func stepRow(_ step: HairRoutineStep) -> some View {
        let done = completedToday.contains(step.id)
        return Button {
            toggle(step)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22)).foregroundStyle(done ? Theme.gold : Theme.muted)
                VStack(alignment: .leading, spacing: 3) {
                    Text(step.title).font(TFont.body(14, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .strikethrough(done, color: Theme.muted)
                    Text(step.detail).font(TFont.body(12)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(step.frequency.replacingOccurrences(of: "_", with: " "))
                    .font(TFont.mono(8.5, weight: .semibold)).tracking(0.8)
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.white.opacity(0.05)).clipShape(Capsule())
            }
            .padding(16)
            .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ step: HairRoutineStep) {
        Haptics.light()
        if completedToday.contains(step.id) { completedToday.remove(step.id) }
        else { completedToday.insert(step.id) }
        let snapshot = Array(completedToday)
        Task { await app.saveCompletedSteps(snapshot) }
    }

    // MARK: Streak

    /// Consecutive days (ending today, or yesterday if today not done yet) with
    /// a check-in that was either scanned or had a completed step.
    private func currentStreak() -> Int {
        let active = Set(checkins
            .filter { $0.scanned || !$0.completedStepIds.isEmpty }
            .map { $0.checkinDate })
        guard !active.isEmpty else { return 0 }

        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!

        func key(_ offset: Int) -> String {
            f.string(from: cal.date(byAdding: .day, value: offset, to: Date())!)
        }

        var start = 0
        if !active.contains(key(0)) {
            if active.contains(key(-1)) { start = -1 } else { return 0 }
        }
        var streak = 0
        var offset = start
        while active.contains(key(offset)) {
            streak += 1
            offset -= 1
        }
        return streak
    }
}

// MARK: - Daily Dashboard (Home hero — daily-habit pivot)

/// Replaces Home's marketing carousel: today's score (or a scan prompt),
/// streak, and entries into Scan / Routine / Progress. The daily loop hub.
struct DailyDashboardCard: View {
    @EnvironmentObject private var app: AppState

    @State private var latest: HairScanRow?
    @State private var checkins: [DailyCheckinRow] = []
    @State private var loaded = false

    private var scannedToday: Bool { latest?.scanDate == AppState.todayUTC }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.07), lineWidth: 9)
                        .frame(width: 92, height: 92)
                    Circle().trim(from: 0, to: CGFloat(latest?.overallScore ?? 0) / 100)
                        .stroke(Theme.goldGlow, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .frame(width: 92, height: 92).rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(latest != nil ? "\(latest!.overallScore)" : "—")
                            .font(TFont.display(30)).foregroundStyle(Theme.text)
                        Text("score").font(TFont.mono(8, weight: .semibold))
                            .tracking(1.2).foregroundStyle(Theme.muted)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(scannedToday ? "You're sharp today." :
                            (latest == nil ? "Let's see your hair." : "Time for today's check-in."))
                        .font(TFont.display(18)).tracking(-0.3).foregroundStyle(Theme.text)
                    Text("🔥 \(hairStreak(from: checkins)) day streak")
                        .font(TFont.mono(11, weight: .bold)).foregroundStyle(Theme.gold)
                    if let h = latest?.headline, !h.isEmpty, scannedToday {
                        Text(h).font(TFont.body(11.5)).foregroundStyle(Theme.muted).lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }

            Button {
                app.push(.dailyScan)
            } label: {
                Text(scannedToday ? "Scan again" : "Scan today")
                    .font(TFont.body(15, weight: .bold)).foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Theme.goldGlow).clipShape(Capsule())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                dashLink("Routine", "list.bullet.clipboard") { app.push(.routine) }
                dashLink("Progress", "chart.line.uptrend.xyaxis") { app.push(.progress) }
            }
        }
        .padding(18)
        .background(
            ZStack(alignment: .topTrailing) {
                Theme.card
                Circle().fill(Theme.gold.opacity(0.18)).frame(width: 160, height: 160)
                    .blur(radius: 70).offset(x: 50, y: -70)
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .task {
            if loaded { return }
            let scans = await app.fetchRecentScans(limit: 1)
            checkins = await app.fetchRecentCheckins()
            latest = scans.first
            loaded = true
        }
    }

    private func dashLink(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(TFont.body(13, weight: .semibold))
            }
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

/// Shared streak calc (consecutive days ending today/yesterday with a check-in
/// that was scanned or had a completed step). Used by Home + Routine.
func hairStreak(from checkins: [DailyCheckinRow]) -> Int {
    let active = Set(checkins
        .filter { $0.scanned || !$0.completedStepIds.isEmpty }
        .map { $0.checkinDate })
    guard !active.isEmpty else { return 0 }
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .iso8601)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "yyyy-MM-dd"
    var cal = Calendar(identifier: .iso8601)
    cal.timeZone = TimeZone(identifier: "UTC")!
    func key(_ o: Int) -> String { f.string(from: cal.date(byAdding: .day, value: o, to: Date())!) }
    var start = 0
    if !active.contains(key(0)) {
        if active.contains(key(-1)) { start = -1 } else { return 0 }
    }
    var streak = 0, offset = start
    while active.contains(key(offset)) { streak += 1; offset -= 1 }
    return streak
}

// MARK: - Hair Progress (trend + timeline)

/// 30-day score trend (Swift Charts) + scan timeline. Reached from the Home
/// dashboard. Named `HairProgressView` to avoid shadowing SwiftUI.ProgressView.
struct HairProgressView: View {
    @EnvironmentObject private var app: AppState

    @State private var scans: [HairScanRow] = []
    @State private var loading = true

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if loading {
                ProgressView().tint(Theme.gold)
            } else if scans.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40, weight: .light)).foregroundStyle(Theme.gold)
                    Text("No scans yet").font(TFont.display(20)).foregroundStyle(Theme.text)
                    Text("Do your first daily scan to start\ntracking your progress.")
                        .font(TFont.body(13)).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center).lineSpacing(3)
                }
            } else {
                content
            }
        }
        .task {
            scans = await app.fetchRecentScans(limit: 30)
            loading = false
        }
    }

    private var chronological: [HairScanRow] { scans.reversed() }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                if let latest = scans.first {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(latest.overallScore)").font(TFont.display(48)).foregroundStyle(Theme.text)
                        Text("/ 100").font(TFont.body(14)).foregroundStyle(Theme.muted)
                        Spacer()
                        if scans.count >= 2 {
                            let d = latest.overallScore - scans[1].overallScore
                            Text("\(d >= 0 ? "▲ +" : "▼ ")\(d)")
                                .font(TFont.mono(12, weight: .bold))
                                .foregroundStyle(d >= 0 ? Theme.gold : Theme.red)
                        }
                    }
                }

                Chart {
                    ForEach(Array(chronological.enumerated()), id: \.element.id) { idx, s in
                        LineMark(x: .value("#", idx), y: .value("Score", s.overallScore))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.gold)
                        AreaMark(x: .value("#", idx), y: .value("Score", s.overallScore))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.gold.opacity(0.12))
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis(.hidden)
                .frame(height: 200)
                .padding(16)
                .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 18))

                Text("HISTORY").font(TFont.mono(10, weight: .bold)).tracking(1.6)
                    .foregroundStyle(Theme.gold)
                VStack(spacing: 8) {
                    ForEach(scans) { s in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.scanDate).font(TFont.body(13, weight: .semibold))
                                    .foregroundStyle(Theme.text)
                                if let h = s.headline, !h.isEmpty {
                                    Text(h).font(TFont.body(11)).foregroundStyle(Theme.muted)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text("\(s.overallScore)")
                                .font(TFont.display(18)).foregroundStyle(Theme.gold)
                        }
                        .padding(14)
                        .background(Theme.card2).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 40)
        }
    }
}

// MARK: - Daily reminder notifications (habit loop)

/// Schedules the once-a-day local notification that drives the daily-scan
/// habit. Called after the user grants notification permission (and safe to
/// call again — it replaces the pending request, so it never stacks).
enum HairNotifications {
    static let dailyID = "trimr.daily.scan"

    static func scheduleDailyReminder(hour: Int = 9, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])

        let content = UNMutableNotificationContent()
        content.title = "Your daily hair check-in 💈"
        content.body = "Scan now for today's score — keep your streak alive."
        content.sound = .default

        var when = DateComponents()
        when.hour = hour
        when.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyID])
    }
}
