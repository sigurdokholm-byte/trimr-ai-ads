import SwiftUI

/// The close of Act I — a Mau-style warm recap. Mirrors the user's onboarding
/// answers back inside labeled cards so the model visibly "gets" them right
/// before the photo climax. Neutral/warm tone (no sales claim — that beat is
/// carried by the next screen, OBConfidenceChart). Cards fade in sequentially.
struct OBFinalReflection: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var visible: Int = 0

    // MARK: Answer → copy

    private var greeting: String {
        state.name.isEmpty ? "thanks for sharing." : "thanks, \(state.name)."
    }

    /// Style goals → lowercase phrase (same mapping as OBReflection2).
    private var goalsPhrase: String {
        guard !state.styleGoals.isEmpty else { return "your best" }
        return state.styleGoals.map { goal -> String in
            switch goal {
            case .professional:   return "professional"
            case .attractive:     return "attractive"
            case .trendy:         return "trendy"
            case .lowMaintenance: return "low-maintenance"
            }
        }.sorted().joined(separator: " and ")
    }

    /// Card-1 copy as (prefix, highlight, suffix) with correct article.
    /// Empty goals → "your best look." (no article); otherwise "a/an … look."
    private var goalLine: (String, String, String) {
        if state.styleGoals.isEmpty {
            return ("", "your best", " look.")
        }
        let vowel = "aeiou".contains(goalsPhrase.first ?? "x")
        return (vowel ? "an " : "a ", goalsPhrase, " look.")
    }

    /// "where you are now" — satisfaction, optionally hair type appended.
    private var nowParts: (String, String, String) {
        let base: (String, String, String)
        if let s = state.satisfaction {
            base = ("you rated your current cut ", "\(s)/10", "")
        } else {
            base = ("you're ", "not happy", " with your current cut")
        }
        if let hair = state.hairType {
            return (base.0, base.1, base.2 + " · \(hair.rawValue) hair")
        }
        return base
    }

    /// Up to 3 obstacle bullets, built from the user's answers.
    private var obstacles: [String] {
        var out: [String] = ["guessing what actually suits your face"]
        if let s = state.satisfaction, s <= 6 {
            out.append("a cut you'd only rate \(s)/10")
        }
        if state.intent == 1 {
            out.append("the memory of a bad haircut")
        }
        if state.productCount == .twoOrThree || state.productCount == .fourPlus {
            out.append("products, but no real system")
        }
        if out.count == 1 {
            out.append("no easy way to know what works")
        }
        return Array(out.prefix(3))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // Atmospheric gold glow behind the header
            RadialGradient(
                colors: [Theme.gold.opacity(0.13), .clear],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                OBHeader(progress: progress, onBack: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header block (i = 1)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(greeting)
                                .font(TFont.display(30))
                                .tracking(-0.6)
                                .foregroundStyle(Theme.text)

                            Text("based on what you've shared, here's where you're at.")
                                .font(TFont.body(15))
                                .foregroundStyle(Theme.muted)
                                .lineSpacing(3)
                        }
                        .reveal(1, visible)
                        .padding(.top, 16)
                        .padding(.bottom, 6)

                        recapCard(emoji: "🎯", label: "where you want to go") {
                            answerText(goalLine.0, goalLine.1, goalLine.2)
                        }
                        .reveal(2, visible)

                        recapCard(emoji: "🪞", label: "where you are now") {
                            answerText(nowParts.0, nowParts.1, nowParts.2)
                        }
                        .reveal(3, visible)

                        recapCard(emoji: "🧱", label: "what's standing in the way") {
                            VStack(alignment: .leading, spacing: 11) {
                                ForEach(obstacles, id: \.self) { line in
                                    HStack(alignment: .firstTextBaseline, spacing: 11) {
                                        Circle()
                                            .fill(Theme.goldGlow)
                                            .frame(width: 6, height: 6)
                                            .shadow(color: Theme.gold.opacity(0.5), radius: 3)
                                            .offset(y: 5)
                                        Text(line)
                                            .font(TFont.body(15))
                                            .foregroundStyle(Theme.text)
                                            .lineSpacing(2)
                                    }
                                }
                            }
                        }
                        .reveal(4, visible)

                        VStack(alignment: .leading, spacing: 14) {
                            Rectangle()
                                .fill(Theme.gold.opacity(0.14))
                                .frame(height: 1)
                                .frame(maxWidth: 60)

                            Text("we see where you are — and where you want to be. let's get you there.")
                                .font(TFont.body(15))
                                .foregroundStyle(Theme.muted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 6)
                        .reveal(5, visible)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                Button(action: onNext) {
                    Text("show me the proof")
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
                .opacity(visible >= 5 ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: visible)
            }
        }
        .task {
            for i in 1...5 {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 550_000_000)
                if Task.isCancelled { return }
                visible = i
            }
        }
    }

    // MARK: Building blocks

    /// White body text with the middle phrase highlighted gold + black weight.
    private func answerText(_ prefix: String, _ highlight: String, _ suffix: String) -> some View {
        (
            Text(prefix)
                .foregroundStyle(Theme.text)
            + Text(highlight)
                .foregroundStyle(Theme.gold)
                .fontWeight(.black)
            + Text(suffix)
                .foregroundStyle(Theme.text)
        )
        .font(TFont.body(16, weight: .medium))
        .lineSpacing(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recapCard<Content: View>(
        emoji: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                // Emoji token
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.gold.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.gold.opacity(0.22), lineWidth: 1)
                        )
                    Text(emoji).font(.system(size: 16))
                }
                .frame(width: 32, height: 32)

                // Label pill
                Text(label)
                    .font(TFont.mono(10))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.gold.opacity(0.12))
                    .clipShape(Capsule())
            }
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1B1610), Theme.card2],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Theme.gold.opacity(0.30), Theme.gold.opacity(0.10)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Sequential reveal helper

private extension View {
    /// Spring fade + slide-up + subtle scale once `visible` reaches this index.
    func reveal(_ index: Int, _ visible: Int) -> some View {
        let shown = visible >= index
        return self
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .scaleEffect(shown ? 1 : 0.97, anchor: .top)
            .animation(.spring(response: 0.5, dampingFraction: 0.78), value: visible)
    }
}
