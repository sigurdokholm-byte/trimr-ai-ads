import SwiftUI

/// Plan-recap screen (Act III). Mau-style: lowercase, conversational, names
/// the user, 4 derived attributes shown as gold-icon rows. Caption highlights
/// the trio of deliverables in gold.
struct OBSummary: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    private struct Row {
        let symbol: String
        let label: String
        let value: String
    }

    private var rows: [Row] {
        let face = state.analysis?.faceShape.capitalized ?? "we'll detect it"
        let hair: String = {
            guard let h = state.hairType else { return "we'll figure it out" }
            return h.rawValue
        }()
        let goals: String = {
            if state.styleGoals.isEmpty { return "look your best" }
            let pretty = state.styleGoals.map { goal -> String in
                switch goal {
                case .professional:    return "professional"
                case .attractive:      return "attractive"
                case .trendy:          return "trendy"
                case .lowMaintenance:  return "low maintenance"
                }
            }.sorted()
            return pretty.prefix(2).joined(separator: " + ")
        }()
        let topMatch = state.analysis?.recommendation.name ?? "coming up next"

        return [
            .init(symbol: "face.smiling.inverse", label: "FACE SHAPE",  value: face),
            .init(symbol: "scribble.variable",    label: "HAIR TYPE",   value: hair),
            .init(symbol: "target",               label: "STYLE GOAL",  value: goals),
            .init(symbol: "scissors",             label: "TOP MATCH",   value: topMatch),
        ]
    }

    private var displayName: String {
        let trimmed = state.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "you" : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 28)

                    Text("your plan")
                        .labelMono(size: 11, tracking: 2.4)
                        .foregroundStyle(Theme.gold)

                    Spacer().frame(height: 10)

                    (
                        Text("alright ")
                            .foregroundStyle(Theme.text)
                        + Text(displayName)
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.black)
                        + Text(", your plan is ready.")
                            .foregroundStyle(Theme.text)
                    )
                    .font(TFont.display(28))
                    .tracking(-0.5)

                    Spacer().frame(height: 28)

                    VStack(spacing: 12) {
                        ForEach(rows.indices, id: \.self) { i in
                            row(rows[i])
                        }
                    }

                    Spacer().frame(height: 22)

                    (
                        Text("3 ")
                            .foregroundStyle(Theme.muted)
                        + Text("personalized cuts")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.semibold)
                        + Text(". a ")
                            .foregroundStyle(Theme.muted)
                        + Text("barber script")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.semibold)
                        + Text(". daily ")
                            .foregroundStyle(Theme.muted)
                        + Text("styling tips")
                            .foregroundStyle(Theme.gold)
                            .fontWeight(.semibold)
                        + Text(".")
                            .foregroundStyle(Theme.muted)
                    )
                    .font(TFont.body(14))
                    .lineSpacing(3)

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 28)
            }

            Button(action: onNext) {
                Text("see my plan")
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
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func row(_ r: Row) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.goldGlow)
                Image(systemName: r.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0x0A0804))
            }
            .frame(width: 38, height: 38)
            .shadow(color: Theme.gold.opacity(0.35), radius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(r.label)
                    .font(TFont.mono(10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)
                Text(r.value)
                    .font(TFont.body(15, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .padding(16)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
