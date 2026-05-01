import SwiftUI

struct OBAge: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let progress: Double
    @Binding var value: Int?

    @State private var selection: Int = 25
    @State private var touched: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            OBHeader(progress: progress, onBack: onBack)

            VStack(spacing: 28) {
                Text("How old are you?")
                    .font(TFont.display(26))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 36)

                Picker("Age", selection: $selection) {
                    ForEach(13...80, id: \.self) { n in
                        Text("\(n)")
                            .font(TFont.display(28))
                            .foregroundStyle(Theme.text)
                            .tag(n)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: 0x1C1812))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
                .onChange(of: selection) { _, _ in touched = true }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                if touched || value != nil {
                    value = selection
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
        .onAppear { if let v = value { selection = v; touched = true } }
    }
}
