import SwiftUI

struct OBReflection2: View {
    @ObservedObject var state: OnboardingState
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double

    @State private var visible: Int = 0

    private var lines: [String] {
        let nameLine = state.name.isEmpty ? "You're with us." : "You're \(state.name)\(state.age.map { ", \($0)" } ?? "")."
        let hairLine = state.hairType.map { "Your hair is \($0.rawValue)." } ?? "We'll figure your hair out next."
        let goalsText: String
        if state.styleGoals.isEmpty {
            goalsText = "You want to look your best."
        } else {
            let goals = state.styleGoals.map(\.rawValue).sorted().joined(separator: " and ")
            goalsText = "You want to look \(goals)."
        }
        return [
            nameLine,
            hairLine,
            goalsText,
            "And you're tired of hoping the next cut works."
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 36)
                ForEach(lines.indices, id: \.self) { i in
                    Text(lines[i])
                        .font(TFont.display(22))
                        .tracking(-0.3)
                        .foregroundStyle(Theme.text)
                        .opacity(i < visible ? 1 : 0)
                        .offset(y: i < visible ? 0 : 8)
                        .animation(.easeOut(duration: 0.4), value: visible)
                }
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(action: onNext) {
                Text("That's me")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Theme.gold).clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(visible >= lines.count ? 1 : 0)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            for i in 1...lines.count {
                try? await Task.sleep(nanoseconds: 400_000_000)
                visible = i
            }
        }
    }
}
