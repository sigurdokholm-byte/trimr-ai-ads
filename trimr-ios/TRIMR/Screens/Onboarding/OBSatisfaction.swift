import SwiftUI

struct OBSatisfaction: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: Int?

    @State private var slider: Double = 5
    @State private var touched: Bool = false

    private var emoji: String {
        switch Int(slider) {
        case 1...3: return "😩"
        case 4...6: return "😐"
        case 7...9: return "🙂"
        default:    return "🤩"
        }
    }
    private var label: String {
        switch Int(slider) {
        case 1...3: return "Hate it"
        case 4...6: return "Meh"
        case 7...9: return "Pretty good"
        default:    return "Perfect"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 28) {
                Text("How happy are you with your current haircut?")
                    .font(TFont.display(24))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                VStack(spacing: 18) {
                    Text("\(Int(slider))")
                        .font(TFont.display(64))
                        .foregroundStyle(Int(slider) >= 7 ? Theme.gold : Theme.text)
                        .contentTransition(.numericText())

                    Slider(value: $slider, in: 1...10, step: 1) { editing in
                        if editing { touched = true }
                    }
                    .tint(Theme.gold)

                    HStack(spacing: 8) {
                        Text(emoji).font(.system(size: 22))
                        Text(label)
                            .font(TFont.body(15, weight: .medium))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(20)
                .background(Color(hex: 0x1C1812))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                if touched {
                    value = Int(slider)
                    onNext()
                }
            } label: {
                Text("Next")
                    .font(TFont.body(16, weight: .semibold))
                    .foregroundStyle(touched ? Color(hex: 0x0A0804) : Color(hex: 0x1A1610))
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(touched ? Theme.gold : Color(hex: 0x5A544A))
                    .clipShape(Capsule())
                    .opacity(touched ? 1 : 0.6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            if let v = value { slider = Double(v); touched = true }
        }
    }
}
