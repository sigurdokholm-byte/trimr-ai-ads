import SwiftUI

enum Theme {
    static let bg      = Color(hex: 0x0E0B08)
    static let bgDeep  = Color(hex: 0x080604)
    static let card    = Color(hex: 0x1C1710)
    static let card2   = Color(hex: 0x14100B)
    static let surface = Color(hex: 0x252015)
    static let text    = Color(hex: 0xF2ECE0)
    static let muted   = Color(hex: 0x8A7D6A)
    static let muted2  = Color(hex: 0x4A4030)
    static let gold    = Color(hex: 0xF5C842)
    static let goldDeep = Color(hex: 0xE2A830)
    static let primary = Color(hex: 0xD4724A)
    static let rose    = Color(hex: 0xC87080)
    static let green   = Color(hex: 0x4ECB71)
    static let red     = Color(hex: 0xE06060)
    static let border  = Color.white.opacity(0.07)
    static let borderStrong = Color.white.opacity(0.12)

    static let goldGlow = LinearGradient(
        colors: [Color(hex: 0xF8D85A), gold, goldDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let primaryGlow = LinearGradient(
        colors: [primary, gold], startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let roseGlow = LinearGradient(
        colors: [rose, primary], startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bottomFade = LinearGradient(
        colors: [bgDeep.opacity(0), bgDeep.opacity(0.9), bgDeep],
        startPoint: .top, endPoint: .bottom
    )
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x080604).opacity(0.0), Color(hex: 0x080604).opacity(0.3), Color(hex: 0x080604).opacity(0.95)],
        startPoint: .top, endPoint: .bottom
    )
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

enum TFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .default) }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .default) }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .monospaced) }
}

struct LabelMono: ViewModifier {
    var size: CGFloat = 10
    var tracking: CGFloat = 2
    func body(content: Content) -> some View {
        content
            .font(TFont.mono(size))
            .tracking(tracking)
            .textCase(.uppercase)
            .foregroundStyle(Theme.muted)
    }
}

extension View {
    func labelMono(size: CGFloat = 10, tracking: CGFloat = 2) -> some View {
        modifier(LabelMono(size: size, tracking: tracking))
    }
}

// MARK: - Sticky bottom CTA above tab bar

struct StickyBottomCTA: ViewModifier {
    let visible: Bool
    @ViewBuilder let button: () -> AnyView

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if visible {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Theme.bgDeep.opacity(0), Theme.bgDeep.opacity(0.85), Theme.bgDeep],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 28)
                        button()
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 96)
                            .frame(maxWidth: .infinity)
                            .background(Theme.bgDeep)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(true)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: visible)
    }
}

extension View {
    func stickyCTA<V: View>(visible: Bool, @ViewBuilder button: @escaping () -> V) -> some View {
        modifier(StickyBottomCTA(visible: visible, button: { AnyView(button()) }))
    }
}
