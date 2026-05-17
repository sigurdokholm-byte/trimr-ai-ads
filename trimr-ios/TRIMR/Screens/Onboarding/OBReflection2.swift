import SwiftUI

/// Final reflection before the climax photo step. Mau-style: line-by-line
/// fade-in, each line conversational, key facts highlighted gold inline,
/// CTA appears once all lines have rendered.
struct OBReflection2: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var visible: Int = 0

    private struct Line {
        let prefix: String
        let highlight: String
        let suffix: String
    }

    private var lines: [Line] {
        let nameHighlight: String
        if !state.name.isEmpty, let age = state.age {
            nameHighlight = "\(state.name), \(age)"
        } else if !state.name.isEmpty {
            nameHighlight = state.name
        } else {
            nameHighlight = "with us"
        }

        let hairHighlight = state.hairType?.rawValue ?? "still figuring it out"

        let goalsText: String
        if state.styleGoals.isEmpty {
            goalsText = "your best"
        } else {
            goalsText = state.styleGoals.map { goal -> String in
                switch goal {
                case .professional:   return "professional"
                case .attractive:     return "attractive"
                case .trendy:         return "trendy"
                case .lowMaintenance: return "low-maintenance"
                }
            }.sorted().joined(separator: " and ")
        }

        return [
            Line(prefix: "you're ",        highlight: nameHighlight,  suffix: "."),
            Line(prefix: "your hair is ",  highlight: hairHighlight,  suffix: "."),
            Line(prefix: "you want a ",    highlight: goalsText,      suffix: " look."),
            Line(prefix: "and you're tired of ", highlight: "bad cuts", suffix: ".")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 18) {
                Spacer().frame(height: 36)

                ForEach(lines.indices, id: \.self) { i in
                    let line = lines[i]
                    (
                        Text(line.prefix)
                            .foregroundStyle(Theme.text)
                        + Text(line.highlight)
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.black)
                        + Text(line.suffix)
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.display(30))
                    .tracking(-0.6)
                    .opacity(i < visible ? 1 : 0)
                    .offset(y: i < visible ? 0 : 8)
                    .animation(.easeOut(duration: 0.4), value: visible)
                }
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(action: onNext) {
                Text("that's me")
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
            .opacity(visible >= lines.count ? 1 : 0)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            for i in 1...lines.count {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 450_000_000)
                if Task.isCancelled { return }
                visible = i
            }
        }
    }
}
